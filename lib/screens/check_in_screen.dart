import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/attendance_service.dart';
import '../core/app_theme.dart';
import 'work_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isProcessing = false;
  bool _isCheckedIn = false;
  bool _isLoadingStatus = true;
  Position? _currentPosition;
  Map<String, dynamic>? _officeLocation;
  double? _distanceToOffice;
  bool _isWithinRange = false;
  String _locationDebug = 'جاري تحديد الموقع...';
  
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
    _initLocationTracking();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    try {
      _officeLocation = await _attendanceService.getOfficeLocation();
      Position pos = await _attendanceService.determinePosition();
      
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          if (_officeLocation != null && _officeLocation!['lat'] != null) {
            _distanceToOffice = Geolocator.distanceBetween(
              pos.latitude, 
              pos.longitude, 
              _officeLocation!['lat'], 
              _officeLocation!['lng']
            );
            
            // Assuming 500m radius is valid (like backend)
            _isWithinRange = _distanceToOffice! <= 500;
            _locationDebug = _isWithinRange ? 'أنت داخل نطاق العمل المسموح به' : 'أنت خارج نطاق العمل المسموح به';
          } else {
            _locationDebug = 'تعذر تحديد موقع الشركة';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationDebug = 'خطأ في تحديد الموقع: برجاء تفعيل الـ GPS');
      }
    }
  }

  Future<void> _loadCurrentStatus() async {
    final status = await _attendanceService.getTodayStatus();
    if (mounted) {
      setState(() {
        _todayAttendance = status;
        _isCheckedIn = status != null && status['checkIn'] != null && status['checkIn']['time'] != null && (status['checkOut'] == null || status['checkOut']['time'] == null);
        _isLoadingStatus = false;
      });
    }
  }

  DateTime? _lastDetected;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isLoadingStatus) return;
    
    final now = DateTime.now();
    if (_lastDetected != null && now.difference(_lastDetected!).inSeconds < 3) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrCode = barcodes.first.rawValue;
      if (qrCode != null) {
        _lastDetected = now;
        setState(() => _isProcessing = true);
        
        if (_isCheckedIn) {
          _showCheckoutConfirmation(qrCode);
        } else {
          _processCheckIn(qrCode);
        }
      }
    }
  }

  Future<void> _processCheckIn(String qrCode) async {
    setState(() => _isProcessing = true);
    final result = await _attendanceService.checkIn(qrCode);
    _handleResult(result, false);
  }

  Future<void> _processCheckOut(String qrToken, {String? note}) async {
    setState(() => _isProcessing = true);
    final result = await _attendanceService.checkOut(qrToken, note: note);
    _handleResult(result, true, qrToken: qrToken);
  }

  void _handleResult(Map<String, dynamic> result, bool isCheckout, {String? qrToken}) {
    if (mounted) {
      if (result['success'] == true) {
        _loadCurrentStatus(); 
        String message = result['message'] ?? (isCheckout ? 'تم تسجيل الانصراف بنجاح!' : 'تم تسجيل الحضور بنجاح!');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );

        if (!isCheckout && result['data'] != null && result['data']['lateMinutes'] > 0) {
          _showLateAlert(result['data']['lateMinutes']);
        }

        if (isCheckout) {
          if (message.contains('submitted for approval') || message.contains('مبكر')) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('تم تقديم الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                content: Text('تم إرسال طلب الانصراف المبكر للإدارة للموافقة عليه.', style: GoogleFonts.cairo()),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          } else {
            _showCheckoutSummary(result['data']);
          }
        } else {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => WorkScreen(attendanceData: result['data']))
          );
        }
      } else {
        setState(() => _isProcessing = false);
        
        if (isCheckout && result['isEarlyCheckout'] == true && qrToken != null) {
          _showEarlyCheckoutNoteDialog(qrToken, result['message']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'فشلت العملية. تأكد من الرمز والموقع.', style: GoogleFonts.cairo()), 
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showEarlyCheckoutNoteDialog(String qrToken, String? message) {
    final TextEditingController noteController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('تنبيه انصراف مبكر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('أنت تحاول الانصراف قبل مواعيد العمل الرسمية.\nالرجاء كتابة سبب المغادرة المبكرة ليتم مراجعته.', style: GoogleFonts.cairo()),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              style: GoogleFonts.cairo(),
              decoration: InputDecoration(
                hintText: 'اكتب السبب هنا...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('الرجاء كتابة السبب', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context);
              _processCheckOut(qrToken, note: noteController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('تقديم الطلب', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutSummary(Map<String, dynamic>? data) {
    int minutes = data?['workedMinutes'] ?? 0;
    int h = minutes ~/ 60;
    int m = minutes % 60;
    String duration = h > 0 ? '$h ساعة و $m دقيقة' : '$m دقيقة';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('أحسنت اليوم! 🎉', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('لقد أنهيت عملك بنجاح. هذا ملخص ليومك:', style: GoogleFonts.cairo(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    duration,
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 45),
                ),
                child: Text('إغلاق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _showCheckoutConfirmation(String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الانصراف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من رغبتك في تسجيل الانصراف والمغادرة؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processCheckOut(qrCode);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('نعم، انصراف', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLateAlert(int minutes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text('تنبيه تأخير', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لقد تأخرت بمقدار $minutes دقيقة', style: GoogleFonts.cairo()),
            const SizedBox(height: 10),
            Text('سيتم تطبيق لائحة الجزاءات وفقاً لسياسة الشركة', 
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  String _getArabicMonth(int month) {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoadingStatus ? 'جاري التحميل...' : (_isCheckedIn ? 'امسح لتسجيل الانصراف' : 'امسح لتسجيل الحضور'),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black87,
        titleTextStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: Stack(
        children: [
          if (!_isLoadingStatus)
            MobileScanner(
              onDetect: _onDetect,
            ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2))
                    ]
                  ),
                ),
                Text(
                  "${_now.day} ${_getArabicMonth(_now.month)} ${_now.year}",
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      const Shadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 1))
                    ]
                  ),
                ),
                if (_todayAttendance != null && _todayAttendance!['lateMinutes'] > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "تأخير: ${_todayAttendance!['lateMinutes']} دقيقة",
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isCheckedIn ? Colors.orange : AppTheme.primaryColor, 
                  width: 4
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_isCheckedIn ? Colors.orange : AppTheme.primaryColor).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              ),
            ),
          ),
          if (_isProcessing || _isLoadingStatus)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isCheckedIn ? Colors.orange : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    _isCheckedIn ? 'انهِ العمل (سجّل الانصراف)' : 'ابدأ العمل (سجّل الحضور)',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isWithinRange ? Colors.green : Colors.red).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isWithinRange ? Icons.location_on : Icons.location_off, 
                          color: _isWithinRange ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationDebug,
                          style: GoogleFonts.cairo(
                            fontSize: 13, 
                            fontWeight: FontWeight.w600,
                            color: _isWithinRange ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 22),
                        onPressed: _initLocationTracking,
                        color: AppTheme.textSecondary,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
