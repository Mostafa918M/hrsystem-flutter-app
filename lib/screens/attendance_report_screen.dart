import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import 'missing_punch_screen.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('attendance/my-history');
      final data = response.data;
      // API returns { status: 'success', data: [...] }
      if (data['status'] == 'success' && data['data'] != null) {
        setState(() { _history = data['data']; _isLoading = false; });
      } else {
        setState(() { _error = data['message'] ?? 'تعذر تحميل السجلات'; _isLoading = false; });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['message'] ?? 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'تعذر الاتصال بالخادم'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('تقرير الحضور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: GoogleFonts.cairo(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchHistory, child: Text('إعادة المحاولة', style: GoogleFonts.cairo())),
                  ]))
              : _history.isEmpty
                  ? Center(child: Text('لا توجد سجلات حضور سابقة', style: GoogleFonts.cairo()))
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _history.length,
                        itemBuilder: (context, index) => _buildRecordCard(_history[index]),
                      ),
                    ),
    );
  }

  Widget _buildRecordCard(dynamic record) {
    final DateTime date = DateTime.parse(record['date']);
    final String formattedDate = DateFormat('dd MMMM yyyy', 'ar').format(date);
    final String dateStr = record['date'];

    final String statusKey = record['status'] ?? 'absent';
    final Map<String, String> statusLabels = {
      'present': 'حاضر', 'late': 'متأخر', 'absent': 'غائب',
      'on_leave': 'إجازة', 'holiday': 'إجازة رسمية', 'half_day': 'نصف يوم',
    };
    final String status = statusLabels[statusKey] ?? statusKey;
    final Color statusColor = statusKey == 'present'
        ? Colors.green
        : statusKey == 'late'
            ? Colors.orange
            : statusKey == 'on_leave' || statusKey == 'holiday'
                ? Colors.indigo
                : Colors.red;

    final checkIn = record['checkIn']?['time'];
    final checkOut = record['checkOut']?['time'];
    final bool hasCheckIn = checkIn != null;
    final bool hasCheckOut = checkOut != null;

    final String checkInStr = hasCheckIn
        ? DateFormat('hh:mm a', 'ar').format(DateTime.parse(checkIn))
        : '--:--';
    final String checkOutStr = hasCheckOut
        ? DateFormat('hh:mm a', 'ar').format(DateTime.parse(checkOut))
        : '--:--';

    final bool canReportMissing = statusKey != 'on_leave' && statusKey != 'holiday'
        && (!hasCheckIn || !hasCheckOut);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(formattedDate, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: statusColor.withOpacity(0.8))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
              child: Text(status, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),

        // Times row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildTimeColumn('الحضور', checkInStr, hasCheckIn, AppTheme.primaryColor),
            Container(width: 1, height: 40, color: Colors.grey.shade200),
            _buildTimeColumn('الانصراف', checkOutStr, hasCheckOut, const Color(0xFFD97706)),
          ]),
        ),

        // Deduction info
        if (record['lateMinutes'] != null && (record['lateMinutes'] as num) > 0) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 8),
                Text(
                  'تأخير ${record['lateMinutes']} دقيقة',
                  style: GoogleFonts.cairo(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (record['deduction']?['amountEGP'] != null && (record['deduction']['amountEGP'] as num) > 0) ...[
                  const Spacer(),
                  Text(
                    '- ${record['deduction']['amountEGP']} EGP',
                    style: GoogleFonts.cairo(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ]),
            ),
          ),
        ],

        // Missing punch button
        if (canReportMissing) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => MissingPunchScreen(
                    date: dateStr,
                    hasCheckIn: hasCheckIn,
                    hasCheckOut: hasCheckOut,
                  )),
                );
                if (result == true) _fetchHistory();
              },
              icon: const Icon(Icons.fingerprint, size: 16),
              label: Text('تبليغ عن بصمة مفقودة', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 38),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildTimeColumn(String label, String time, bool hasValue, Color color) {
    return Column(children: [
      Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(
        time,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: hasValue ? AppTheme.textPrimary : Colors.grey.shade300,
        ),
      ),
      if (!hasValue)
        Text('مفقودة', style: GoogleFonts.cairo(fontSize: 10, color: color.withOpacity(0.6), fontWeight: FontWeight.bold)),
    ]);
  }
}
