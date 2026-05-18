import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/shift_service.dart';
import '../core/app_theme.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  final ShiftService _shiftService = ShiftService();
  List<DaySchedule> _schedule = [];
  bool _isLoading = true;
  String? _error;

  static const Map<String, String> _dayArabic = {
    'sunday': 'الأحد',
    'monday': 'الإثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
    'saturday': 'السبت',
  };

  static const Map<String, Color> _typeColor = {
    'regular': Color(0xFF7C3AED),
    'split': Color(0xFF0284C7),
    'overnight': Color(0xFF4338CA),
    'flexible': Color(0xFFD97706),
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final schedule = await _shiftService.getMySchedule();
      if (mounted) setState(() { _schedule = schedule; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'تعذر تحميل الجدول'; _isLoading = false; });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _isToday(DaySchedule day) {
    final dateStr = day.date;
    final today = DateTime.now();
    final d = DateTime.tryParse(dateStr);
    return d != null && d.year == today.year && d.month == today.month && d.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('جدولي الأسبوعي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSchedule,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: GoogleFonts.cairo(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadSchedule, child: Text('إعادة المحاولة', style: GoogleFonts.cairo())),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadSchedule,
                  color: AppTheme.primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Today's highlight
                      ..._schedule.where(_isToday).map((day) => _buildTodayCard(day)),

                      const SizedBox(height: 20),
                      Text(
                        'الأسبوع القادم',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      // All 7 days
                      ..._schedule.map((day) => _buildDayCard(day)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTodayCard(DaySchedule day) {
    final shift = day.shift;
    final color = shift != null ? (_typeColor[shift.type] ?? AppTheme.primaryColor) : AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('اليوم', style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(_formatDate(day.date), style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (shift != null) ...[
          Text(shift.name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(shift.displayHours, style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text('فترة السماح: ${shift.gracePeriodMins} دقيقة', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
          ]),
        ] else ...[
          Text('يوم إجازة', style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('لا يوجد وردية اليوم', style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.8), fontSize: 13)),
        ],
      ]),
    );
  }

  Widget _buildDayCard(DaySchedule day) {
    final isToday = _isToday(day);
    final shift = day.shift;
    final typeColor = shift != null ? (_typeColor[shift.type] ?? AppTheme.primaryColor) : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade100,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              _dayArabic[day.dayName]?.substring(0, 2) ?? '--',
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
            ),
          ]),
        ),
        title: Row(children: [
          Text(
            _dayArabic[day.dayName] ?? day.dayName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14,
              color: isToday ? AppTheme.primaryColor : AppTheme.textPrimary),
          ),
          const SizedBox(width: 8),
          Text(_formatDate(day.date), style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
          if (isToday) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4)),
              child: Text('اليوم', style: GoogleFonts.cairo(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        subtitle: shift != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 2),
                Text(shift.name, style: GoogleFonts.cairo(fontSize: 12, color: typeColor, fontWeight: FontWeight.w600)),
                Text(
                  shift.displayHours,
                  style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary).copyWith(fontFamily: 'monospace'),
                ),
              ])
            : Text('يوم إجازة', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400)),
        trailing: shift != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _shiftTypeArabic(shift.type),
                  style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                ),
              )
            : const Icon(Icons.beach_access_rounded, color: Colors.grey, size: 18),
      ),
    );
  }

  String _shiftTypeArabic(String type) {
    switch (type) {
      case 'regular': return 'عادية';
      case 'split': return 'مقسمة';
      case 'overnight': return 'ليلية';
      case 'flexible': return 'مرنة';
      default: return type;
    }
  }
}
