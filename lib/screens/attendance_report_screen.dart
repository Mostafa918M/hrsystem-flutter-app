import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../services/attendance_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  List<dynamic> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final apiClient = ApiClient();

      final response = await apiClient.dio.get('attendance/my-history');

      final data = response.data;
      if (data['success'] == true) {
        setState(() {
          _history = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['message'] ?? 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: GoogleFonts.cairo(color: Colors.red)))
              : _history.isEmpty
                  ? Center(child: Text('لا توجد سجلات حضور سابقة', style: GoogleFonts.cairo()))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final record = _history[index];
                        return _buildRecordCard(record);
                      },
                    ),
    );
  }

  Widget _buildRecordCard(dynamic record) {
    final DateTime date = DateTime.parse(record['date']);
    final String formattedDate = DateFormat('dd MMMM yyyy', 'ar').format(date);
    final String status = record['status'] == 'present' ? 'حاضر' : (record['status'] == 'late' ? 'متأخر' : 'غائب');
    final Color statusColor = record['status'] == 'present' ? Colors.green : (record['status'] == 'late' ? Colors.orange : Colors.red);
    
    final checkIn = record['checkIn']?['time'];
    final checkOut = record['checkOut']?['time'];
    
    final String checkInStr = checkIn != null ? DateFormat('hh:mm a', 'ar').format(DateTime.parse(checkIn)) : '--:--';
    final String checkOutStr = checkOut != null ? DateFormat('hh:mm a', 'ar').format(DateTime.parse(checkOut)) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: statusColor.withOpacity(0.8))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('الحضور', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(checkInStr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Column(
                  children: [
                    Text('الانصراف', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(checkOutStr, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
