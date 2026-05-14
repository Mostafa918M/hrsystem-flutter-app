import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../providers/auth_provider.dart';

class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  List<dynamic> _loanRequests = [];

  @override
  void initState() {
    super.initState();
    _loadLoanHistory();
  }

  Future<void> _loadLoanHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('loans/my');
      
      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _loanRequests = response.data['data'] ?? [];
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل سجل السلف', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال مبلغ صحيح أكبر من الصفر', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        'loans/request',
        data: {
          'amount': amount,
          'reason': _reasonController.text.trim(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تقديم طلب السلفة بنجاح', style: GoogleFonts.cairo()),
              backgroundColor: Colors.green,
            ),
          );
          _amountController.clear();
          _reasonController.clear();
          // Reload history and try auto-login to refresh user status
          _loadLoanHistory();
          Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'فشل تقديم الطلب', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال بالخادم', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getStatusArabic(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('طلب سلفة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadLoanHistory,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ACTIVE BALANCE SECTION
                Text('السلف القائمة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'إجمالي السلف النشطة',
                            style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 24),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${NumberFormat('#,###').format(user?.loans ?? 0)} جنيه',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('طلب سلفة مالية جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                        const SizedBox(height: 20),
                        
                        Text('قيمة السلفة (جنيه مصري)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'مثال: 3000',
                            hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'الرجاء كتابة المبلغ المطلق';
                            if (double.tryParse(val) == null) return 'الرجاء إدخال رقم صحيح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        Text('سبب السلفة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          style: GoogleFonts.cairo(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'اكتب تفاصيل سبب السلفة هنا...',
                            hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'الرجاء كتابة السبب بالتفصيل' : null,
                        ),
                        const SizedBox(height: 24),

                        _isSubmitting
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 2,
                                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                child: Text('تقديم طلب السلفة الآن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // LOAN HISTORY SECTION
                Text('طلباتي السابقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),

                _isLoadingHistory
                    ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                    : _loanRequests.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.monetization_on_outlined, size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد طلبات سلف سابقة لديك',
                                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _loanRequests.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final loan = _loanRequests[index];
                              final amount = loan['amount'] ?? 0;
                              final dateStr = loan['createdAt'] != null
                                  ? DateFormat('yyyy-MM-dd').format(DateTime.parse(loan['createdAt']))
                                  : '';
                              final status = loan['status'] ?? 'pending';
                              final reason = loan['reason'] ?? '';
                              final reviewNote = loan['reviewNote'] ?? '';

                              return Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
                                  ],
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${NumberFormat('#,###').format(amount)} جنيه',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _getStatusArabic(status),
                                            style: GoogleFonts.cairo(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'تاريخ الطلب: $dateStr',
                                      style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'السبب: $reason',
                                      style: GoogleFonts.cairo(color: Colors.black87, fontSize: 13),
                                    ),
                                    if (reviewNote.toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'ملاحظة الإدارة: $reviewNote',
                                          style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 12),
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
        ),
      ),
    );
  }
}
