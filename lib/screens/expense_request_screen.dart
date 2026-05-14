import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:dio/dio.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';

class ExpenseRequestScreen extends StatefulWidget {
  const ExpenseRequestScreen({super.key});

  @override
  State<ExpenseRequestScreen> createState() => _ExpenseRequestScreenState();
}

class _ExpenseRequestScreenState extends State<ExpenseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCategory = 'travel';
  bool _isSubmitting = false;
  bool _isLoadingHistory = true;
  List<dynamic> _expenseRequests = [];

  final Map<String, String> _categories = {
    'travel': 'سفر وانتقالات',
    'meals': 'وجبات ومأكولات',
    'supplies': 'أدوات ومستلزمات مكتبية',
    'utilities': 'فواتير وخدمات',
    'training': 'تدريب وتطوير',
    'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();
    _loadExpenseHistory();
  }

  Future<void> _loadExpenseHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('expenses/my-requests');
      
      if (response.statusCode == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _expenseRequests = response.data['data'] ?? [];
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل سجل طلبات المصاريف', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء اختيار تاريخ الفاتورة وإكمال البيانات المطلوبة', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إدخال قيمة صحيحة أكبر من الصفر', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post(
        'expenses/requests',
        data: {
          'date': _selectedDate!.toIso8601String(),
          'amount': amount,
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تقديم طلب المصاريف بنجاح', style: GoogleFonts.cairo()),
              backgroundColor: Colors.green,
            ),
          );
          _amountController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedDate = null;
            _selectedCategory = 'travel';
          });
          _loadExpenseHistory();
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
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
      setState(() => _selectedDate = picked);
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
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('طلب استرداد مصاريف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadExpenseHistory,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // POLICY CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withOpacity(0.3),
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
                            'سياسة تعويض المصاريف',
                            style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 24),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'يرجى تقديم مستند أو فاتورة مصورة صالحة لأي مطالبة يتم تسجيلها لسرعة المراجعة.',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, height: 1.5),
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
                        Text('طلب تعويض مصاريف جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                        const SizedBox(height: 20),

                        Text('تصنيف المصروفات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 15),
                          items: _categories.entries.map((e) {
                            return DropdownMenuItem(value: e.key, child: Text(e.value));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                        const SizedBox(height: 20),
                        
                        Text('تاريخ الفاتورة / المصروف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
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
                                  _selectedDate == null 
                                      ? 'اختر التاريخ...' 
                                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                  style: GoogleFonts.cairo(fontSize: 14, color: _selectedDate == null ? Colors.grey : Colors.black87),
                                ),
                                Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryColor.withOpacity(0.7)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('قيمة المبلغ (جنيه مصري)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'مثال: 450',
                            hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: const Icon(Icons.wallet_rounded, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'الرجاء كتابة قيمة المبلغ المطلوب';
                            if (double.tryParse(val) == null) return 'الرجاء إدخال رقم صحيح';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        Text('وصف المصروفات بالتفصيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: GoogleFonts.cairo(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'اكتب تفاصيل الفاتورة أو سبب هذا المصروف هنا...',
                            hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'الرجاء كتابة التفاصيل' : null,
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
                                child: Text('تقديم طلب التعويض الآن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // EXPENSE HISTORY SECTION
                Text('طلباتي السابقة للمصاريف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),

                _isLoadingHistory
                    ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                    : _expenseRequests.isEmpty
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
                                Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد طلبات مصاريف سابقة لديك',
                                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _expenseRequests.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final exp = _expenseRequests[index];
                              final amount = exp['amount'] ?? 0;
                              final cat = exp['category'] ?? 'other';
                              final dateStr = exp['date'] != null
                                  ? DateFormat('yyyy-MM-dd').format(DateTime.parse(exp['date']))
                                  : '';
                              final status = exp['status'] ?? 'pending';
                              final desc = exp['description'] ?? '';
                              final hrNotes = exp['hrNotes'] ?? '';

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
                                          '$amount جنيه مصري (${_categories[cat] ?? cat})',
                                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
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
                                      'تاريخ الفاتورة: $dateStr',
                                      style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'الوصف: $desc',
                                      style: GoogleFonts.cairo(color: Colors.black87, fontSize: 13),
                                    ),
                                    if (hrNotes.toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'ملاحظة الموارد البشرية: $hrNotes',
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
