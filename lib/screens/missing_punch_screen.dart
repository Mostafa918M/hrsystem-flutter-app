import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/missing_punch_service.dart';
import '../core/app_theme.dart';

class MissingPunchScreen extends StatefulWidget {
  final String date;
  final bool hasCheckIn;
  final bool hasCheckOut;

  const MissingPunchScreen({
    super.key,
    required this.date,
    required this.hasCheckIn,
    required this.hasCheckOut,
  });

  @override
  State<MissingPunchScreen> createState() => _MissingPunchScreenState();
}

class _MissingPunchScreenState extends State<MissingPunchScreen> {
  final MissingPunchService _service = MissingPunchService();
  final TextEditingController _reasonController = TextEditingController();

  String _type = 'check_in';
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  bool _isSubmitting = false;

  static const Map<String, String> _typeLabels = {
    'check_in': 'بصمة حضور مفقودة',
    'check_out': 'بصمة انصراف مفقودة',
    'both': 'كلاهما (حضور وانصراف)',
  };

  @override
  void initState() {
    super.initState();
    // Pre-select type based on what's missing
    if (!widget.hasCheckIn && !widget.hasCheckOut) {
      _type = 'both';
    } else if (!widget.hasCheckIn) {
      _type = 'check_in';
    } else if (!widget.hasCheckOut) {
      _type = 'check_out';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? const TimeOfDay(hour: 9, minute: 0) : const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) _checkInTime = picked;
        else _checkOutTime = picked;
      });
    }
  }

  bool get _needsCheckIn => _type == 'check_in' || _type == 'both';
  bool get _needsCheckOut => _type == 'check_out' || _type == 'both';

  Future<void> _submit() async {
    if (_reasonController.text.trim().length < 5) {
      _showSnack('الرجاء كتابة سبب مفصّل (5 أحرف على الأقل)', Colors.red);
      return;
    }
    if (_needsCheckIn && _checkInTime == null) {
      _showSnack('الرجاء تحديد وقت الحضور المطلوب', Colors.red);
      return;
    }
    if (_needsCheckOut && _checkOutTime == null) {
      _showSnack('الرجاء تحديد وقت الانصراف المطلوب', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _service.submit(
      date: widget.date,
      type: _type,
      requestedCheckIn: _needsCheckIn ? _formatTime(_checkInTime!) : null,
      requestedCheckOut: _needsCheckOut ? _formatTime(_checkOutTime!) : null,
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSnack(result['message'] ?? 'تم تقديم الطلب بنجاح', Colors.green);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnack(result['message'] ?? 'فشل تقديم الطلب', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('تبليغ عن بصمة مفقودة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // Date card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 10),
              Text('التاريخ المحدد: ${widget.date}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ]),
          ),

          const SizedBox(height: 20),

          // Type selection
          Text('نوع البصمة المفقودة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          ...['check_in', 'check_out', 'both'].map((t) => _buildTypeCard(t)),

          const SizedBox(height: 20),

          // Time pickers
          if (_needsCheckIn) ...[
            _buildTimePicker(
              label: 'وقت الحضور المطلوب',
              time: _checkInTime,
              icon: Icons.login_rounded,
              color: AppTheme.primaryColor,
              onTap: () => _pickTime(true),
            ),
            const SizedBox(height: 12),
          ],
          if (_needsCheckOut) ...[
            _buildTimePicker(
              label: 'وقت الانصراف المطلوب',
              time: _checkOutTime,
              icon: Icons.logout_rounded,
              color: const Color(0xFFD97706),
              onTap: () => _pickTime(false),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),

          // Reason
          Text('سبب الطلب *', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            style: GoogleFonts.cairo(),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'اشرح سبب نسيان تسجيل البصمة...',
              hintStyle: GoogleFonts.cairo(color: AppTheme.textSecondary),
            ),
          ),

          const SizedBox(height: 28),

          // Submit button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('تقديم الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ]),
      ),
    );
  }

  Widget _buildTypeCard(String t) {
    final isSelected = _type == t;
    return GestureDetector(
      onTap: () => setState(() => _type = t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400, width: 2),
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
          ),
          const SizedBox(width: 12),
          Text(_typeLabels[t]!, style: GoogleFonts.cairo(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
          )),
        ]),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: time != null ? color.withOpacity(0.4) : Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(
                time != null ? _formatTime(time) : 'اضغط لتحديد الوقت',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: time != null ? AppTheme.textPrimary : Colors.grey.shade400,
                ).copyWith(fontFamily: 'monospace'),
              ),
            ]),
          ),
          Icon(Icons.access_time_rounded, color: color.withOpacity(0.5), size: 20),
        ]),
      ),
    );
  }
}
