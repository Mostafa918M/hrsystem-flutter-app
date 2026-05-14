import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/encashment_service.dart';
import '../core/app_theme.dart';

class EncashmentRequestScreen extends StatefulWidget {
  const EncashmentRequestScreen({super.key});

  @override
  State<EncashmentRequestScreen> createState() => _EncashmentRequestScreenState();
}

class _EncashmentRequestScreenState extends State<EncashmentRequestScreen> {
  final EncashmentService _service = EncashmentService();
  final TextEditingController _daysController = TextEditingController(text: '1');

  bool _isLoadingHistory = true;
  bool _isSubmitting = false;
  String _encashmentType = 'vacation'; // 'vacation' or 'stb'
  List<dynamic> _encashments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeId = authProvider.user?.employeeId ?? authProvider.user?.id;
    if (employeeId == null) return;

    setState(() => _isLoadingHistory = true);

    try {
      final res = await _service.getEmployeeEncashments(employeeId);
      if (mounted) {
        setState(() {
          _encashments = res;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _submitRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeId = authProvider.user?.employeeId ?? authProvider.user?.id;
    if (employeeId == null) return;

    setState(() => _isSubmitting = true);

    Map<String, dynamic>? res;
    if (_encashmentType == 'vacation') {
      final days = int.tryParse(_daysController.text.trim()) ?? 0;
      if (days <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid number of days', style: GoogleFonts.cairo())),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      res = await _service.requestVacationEncashment(
        employeeId: employeeId,
        unusedDays: days,
      );
    } else {
      res = await _service.requestSTBEncashment(
        employeeId: employeeId,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Encashment request submitted successfully', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
        );
        _daysController.text = '1';
        await _loadHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit encashment request', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'تسييل الإجازات ونهاية الخدمة',
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
            // Header Card
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
                      'مزايا الموظفين',
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لوحة التحويل النقدي',
                    style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك طلب صرف بدل نقدي لرصيد الإجازات السنوية أو التقديم على صرف مكافأة نهاية الخدمة.',
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'اختر نوع الصرف',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),

            // Category selector tabs
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _encashmentType = 'vacation'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _encashmentType == 'vacation' ? AppTheme.secondaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _encashmentType == 'vacation' ? AppTheme.secondaryColor : Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.beach_access, color: _encashmentType == 'vacation' ? Colors.white : AppTheme.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'رصيد الإجازات',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _encashmentType == 'vacation' ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _encashmentType = 'stb'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _encashmentType == 'stb' ? AppTheme.secondaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _encashmentType == 'stb' ? AppTheme.secondaryColor : Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.handshake, color: _encashmentType == 'stb' ? Colors.white : AppTheme.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'مكافأة نهاية الخدمة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _encashmentType == 'stb' ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
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
                  if (_encashmentType == 'vacation') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('رصيد الإجازات المتاح:', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('${user?.annualLeaveBalance ?? 0} يوم', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'عدد الأيام المطلوب صرفها',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _daysController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'مكافأة نهاية الخدمة (STB)',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يتم احتساب المكافأة وفقاً لقانون العمل المصري بناءً على سنوات الخدمة. يشترط إمضاء 3 سنوات على الأقل.',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('تقديم طلب الصرف', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'سجل طلبات الصرف',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),

            _isLoadingHistory
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : _encashments.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            'لا يوجد طلبات صرف سابقة',
                            style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _encashments.length,
                        itemBuilder: (context, idx) {
                          final enc = _encashments[idx];
                          final type = enc['type'] ?? 'vacation';
                          final status = enc['status'] ?? 'pending';
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
                                      type == 'stb' ? 'صرف نهاية الخدمة' : 'صرف رصيد إجازات',
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
                                    Text(type == 'vacation' ? 'الأيام المطلوب صرفها: ${enc['unusedDays']} يوم' : 'مكافأة قانون العمل', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
                                    Text('${enc['calculatedAmount']} ج.م', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                                  ],
                                ),
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
