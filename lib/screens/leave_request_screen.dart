import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../providers/auth_provider.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'annual';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _leaveTypes = {
    'annual': 'إجازة سنوية',
    'sick': 'إجازة مرضية',
    'emergency': 'إجازة طارئة',
    'unpaid': 'إجازة غير مدفوعة',
    'wfh': 'عمل من المنزل',
  };

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إكمال جميع البيانات', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تاريخ النهاية لا يمكن أن يكون قبل البداية', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        'leaves/request',
        data: {
          'type': _leaveType,
          'startDate': _startDate!.toIso8601String(),
          'endDate': _endDate!.toIso8601String(),
          'reason': _reasonController.text.trim(),
        },
      );

      // Note: Backend response might vary, usually checking status code or a success field
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تقديم الطلب بنجاح', style: GoogleFonts.cairo()), backgroundColor: Colors.green),
          );
          // Refresh user data to update balances
          Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
          Navigator.pop(context);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data['message'] ?? 'فشل تقديم الطلب', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاتصال بالخادم', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow some backdating if needed
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('طلب إجازة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BALANCES SECTION
              Text('أرصدة الإجازات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildBalanceCard('سنوية', user?.annualLeaveBalance ?? 0, Colors.blue),
                  const SizedBox(width: 12),
                  _buildBalanceCard('مرضية', user?.sickLeaveBalance ?? 0, Colors.red),
                  const SizedBox(width: 12),
                  _buildBalanceCard('طارئة', user?.emergencyLeaveBalance ?? 0, Colors.orange),
                ],
              ),
              const SizedBox(height: 32),

              // FORM SECTION
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تفاصيل الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                    const SizedBox(height: 20),
                    
                    Text('نوع الإجازة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _leaveType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 15),
                      items: _leaveTypes.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                      }).toList(),
                      onChanged: (val) => setState(() => _leaveType = val!),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: _buildDatePicker('من تاريخ', _startDate, true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDatePicker('إلى تاريخ', _endDate, false)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text('السبب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: GoogleFonts.cairo(),
                      decoration: InputDecoration(
                        hintText: 'اكتب سبب الإجازة هنا...',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'الرجاء كتابة السبب' : null,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                      ),
                      child: Text('تقديم الطلب الآن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value.toString(), style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null ? '00/00' : DateFormat('dd/MM').format(date),
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryColor.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
