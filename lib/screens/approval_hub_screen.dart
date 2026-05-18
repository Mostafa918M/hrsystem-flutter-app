import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';

class ApprovalHubScreen extends StatefulWidget {
  const ApprovalHubScreen({super.key});

  @override
  State<ApprovalHubScreen> createState() => _ApprovalHubScreenState();
}

class _ApprovalHubScreenState extends State<ApprovalHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  
  List<dynamic> _leaves = [];
  List<dynamic> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final leavesRes = await _apiClient.dio.get('leaves');
      final loansRes = await _apiClient.dio.get('loans');

      if (mounted) {
        setState(() {
          // Filter to show only requests pending manager approval
          _leaves = (leavesRes.data['data'] as List)
              .where((req) => req['managerApproval'] == 'pending')
              .toList();
          _loans = (loansRes.data['data'] as List)
              .where((req) => req['managerApproval'] == 'pending')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب الطلبات', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reviewRequest(String type, String id, String status) async {
    try {
      await _apiClient.dio.patch('$type/$id/review', data: {
        'status': status,
        'reviewNote': 'Reviewed via Mobile App',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? 'تمت الموافقة بنجاح' : 'تم الرفض بنجاح', style: GoogleFonts.cairo()),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تنفيذ الإجراء', style: GoogleFonts.cairo()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('مركز الموافقات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'الإجازات'),
            Tab(text: 'السلف المالية'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_leaves, 'leaves'),
                _buildList(_loans, 'loans'),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا توجد طلبات معلقة', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final empName = item['employeeId']?['fullName'] ?? 'موظف';
          
          String title = '';
          String details = '';
          if (type == 'leaves') {
            title = 'طلب إجازة - $empName';
            final start = DateTime.tryParse(item['startDate'] ?? '') ?? DateTime.now();
            final end = DateTime.tryParse(item['endDate'] ?? '') ?? DateTime.now();
            final days = end.difference(start).inDays + 1;
            details = 'لمدة $days يوم/أيام\nالسبب: ${item['reason'] ?? ''}';
          } else {
            title = 'طلب سلفة - $empName';
            details = 'المبلغ: ${item['amount'] ?? 0}\nالسبب: ${item['reason'] ?? ''}';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(type == 'leaves' ? Icons.calendar_today : Icons.money, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details,
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _reviewRequest(type, item['_id'], 'rejected'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('رفض', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _reviewRequest(type, item['_id'], 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('موافقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
