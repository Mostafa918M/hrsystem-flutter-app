import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../providers/auth_provider.dart';
import '../services/vacation_advance_service.dart';

class VacationAdvanceScreen extends StatefulWidget {
  const VacationAdvanceScreen({super.key});

  @override
  State<VacationAdvanceScreen> createState() => _VacationAdvanceScreenState();
}

class _VacationAdvanceScreenState extends State<VacationAdvanceScreen> {
  final VacationAdvanceService _service = VacationAdvanceService();
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingLeaves = true;
  bool _isLoadingAdvances = true;
  bool _isCalculating = false;
  bool _isSubmitting = false;

  List<dynamic> _leaves = [];
  List<dynamic> _advances = [];

  String? _selectedLeaveId;
  int _monthsCovered = 1;
  Map<String, dynamic>? _calculation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeId = authProvider.user?.employeeId ?? authProvider.user?.id;
    if (employeeId == null) return;

    setState(() {
      _isLoadingLeaves = true;
      _isLoadingAdvances = true;
    });

    try {
      // Fetch user leaves
      final resLeaves = await _apiClient.dio.get('leaves/my');
      if (resLeaves.statusCode == 200) {
        final allLeaves = resLeaves.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _leaves = allLeaves.where((lv) => lv['status'] == 'approved').toList();
            _isLoadingLeaves = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLeaves = false);
    }

    await _loadAdvances(employeeId);
  }

  Future<void> _loadAdvances(String employeeId) async {
    try {
      final res = await _service.getEmployeeAdvances(employeeId);
      if (mounted) {
        setState(() {
          _advances = res;
          _isLoadingAdvances = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAdvances = false);
    }
  }

  Future<void> _onLeaveOrMonthsChanged() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeId = authProvider.user?.employeeId ?? authProvider.user?.id;
    if (employeeId == null || _selectedLeaveId == null) {
      setState(() => _calculation = null);
      return;
    }

    setState(() => _isCalculating = true);

    final res = await _service.calculateAdvance(
      employeeId: employeeId,
      leaveId: _selectedLeaveId!,
      monthsCovered: _monthsCovered,
    );

    if (mounted) {
      setState(() {
        _calculation = res;
        _isCalculating = false;
      });
    }
  }

  Future<void> _submitAdvanceRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeId = authProvider.user?.employeeId ?? authProvider.user?.id;

    if (employeeId == null || _selectedLeaveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار طلب إجازة معتمد أولاً', style: GoogleFonts.cairo())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await _service.requestAdvance(
      employeeId: employeeId,
      leaveId: _selectedLeaveId!,
      monthsCovered: _monthsCovered,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تقديم طلب سلفة الإجازة بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
        );
        _selectedLeaveId = null;
        _calculation = null;
        await _loadAdvances(employeeId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تقديم طلب سلفة الإجازة', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'سلفة راتب الإجازة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'الخدمات المالية',
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'طلب راتب الإجازة مقدماً',
                    style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يتيح لك النظام صرف الراتب الأساسي مقدماً عن فترة إجازتك السنوية المعتمدة قبل الخروج إليها.',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'طلب سلفة جديد',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),

            // Form container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر الإجازة المعتمدة',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingLeaves
                      ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                      : _leaves.isEmpty
                          ? Text('لا يوجد طلبات إجازة معتمدة', style: GoogleFonts.cairo(fontSize: 14, color: Colors.red))
                          : DropdownButtonFormField<String>(
                              value: _selectedLeaveId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.backgroundColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _leaves.map((lv) {
                                final start = DateFormat('yyyy-MM-dd').format(DateTime.parse(lv['startDate']));
                                final end = DateFormat('yyyy-MM-dd').format(DateTime.parse(lv['endDate']));
                                return DropdownMenuItem<String>(
                                  value: lv['_id']?.toString() ?? lv['id']?.toString(),
                                  child: Text('من $start إلى $end (${lv['totalDays']} يوم)', style: GoogleFonts.cairo(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedLeaveId = val);
                                _onLeaveOrMonthsChanged();
                              },
                            ),

                  const SizedBox(height: 20),
                  Text(
                    'تغطية فترة السلفة',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _monthsCovered,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('سلفة راتب شهر واحد', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 2, child: Text('سلفة راتب شهرين', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 3, child: Text('سلفة راتب 3 أشهر', style: GoogleFonts.cairo())),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _monthsCovered = val);
                        _onLeaveOrMonthsChanged();
                      }
                    },
                  ),

                  if (_isCalculating)
                    const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator())),

                  if (_calculation != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('معاينة الحساب النظري', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الراتب الإجمالي النسبي:', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textPrimary)),
                              Text('${_calculation!['grossSalary']} ج.م', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الاستقطاعات:', style: GoogleFonts.cairo(fontSize: 13, color: Colors.red.shade700)),
                              Text('${_calculation!['deductions']} ج.م', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                            ],
                          ),
                          Divider(height: 20, color: AppTheme.primaryColor.withOpacity(0.2)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('صافي السلفة المستحقة:', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text('${_calculation!['netAmount']} ج.م', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _selectedLeaveId == null ? null : _submitAdvanceRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('تقديم طلب السلفة', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'سجل سلف الإجازات',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),

            // Advances List
            _isLoadingAdvances
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : _advances.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            'لا يوجد سلف إجازات سابقة',
                            style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _advances.length,
                        itemBuilder: (context, idx) {
                          final adv = _advances[idx];
                          final status = adv['status'] ?? 'pending';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'سلفة راتب ${adv['monthsCovered']} شهر',
                                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'approved'
                                            ? Colors.green.withOpacity(0.1)
                                            : status == 'rejected'
                                                ? Colors.red.withOpacity(0.1)
                                                : Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status == 'approved' ? 'تمت الموافقة' : status == 'rejected' ? 'مرفوض' : 'قيد المراجعة',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: status == 'approved'
                                              ? Colors.green
                                              : status == 'rejected'
                                                  ? Colors.red
                                                  : Colors.amber.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('مبلغ الصرف الصافي:', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
                                    Text('${adv['netAmount']} ج.م', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                                  ],
                                ),
                                if (adv['returnReminderSent'] == true) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.notifications_active, color: AppTheme.textSecondary, size: 16),
                                        const SizedBox(width: 8),
                                        Text('تم إرسال إشعار تذكير العودة', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
