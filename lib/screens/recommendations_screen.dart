import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recommendation_service.dart';
import '../core/app_theme.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final RecommendationService _service = RecommendationService();
  List<RecommendationItem> _recs = [];
  bool _isLoading = true;

  static const Map<String, Map<String, dynamic>> _typeConfig = {
    'overtime':            {'icon': Icons.access_time_filled_rounded,       'color': Color(0xFF7C3AED), 'bg': Color(0xFFF5F3FF)},
    'compensatory_leave':  {'icon': Icons.event_available_rounded,          'color': Color(0xFF0284C7), 'bg': Color(0xFFEFF6FF)},
    'time_off':            {'icon': Icons.beach_access_rounded,             'color': Color(0xFF059669), 'bg': Color(0xFFECFDF5)},
    'excessive_lateness':  {'icon': Icons.warning_amber_rounded,            'color': Color(0xFFDC2626), 'bg': Color(0xFFFEF2F2)},
    'missing_document':    {'icon': Icons.insert_drive_file_outlined,       'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final recs = await _service.getMy();
    if (mounted) setState(() { _recs = recs; _isLoading = false; });
  }

  Future<void> _apply(RecommendationItem rec) async {
    final result = await _service.apply(rec.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? '', style: GoogleFonts.cairo()),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ));
      if (result['success'] == true) _load();
    }
  }

  Future<void> _dismiss(RecommendationItem rec) async {
    final result = await _service.dismiss(rec.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? '', style: GoogleFonts.cairo()),
        backgroundColor: result['success'] == true ? Colors.orange : Colors.red,
      ));
      if (result['success'] == true) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('التوصيات الذكية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: _recs.isEmpty
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Column(children: [
                        Icon(Icons.auto_awesome_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('لا توجد توصيات حالياً', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('ستظهر هنا التوصيات المتعلقة بورديتك وإجازاتك', style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 12), textAlign: TextAlign.center),
                      ]),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _recs.length,
                      itemBuilder: (context, i) => _buildCard(_recs[i]),
                    ),
            ),
    );
  }

  Widget _buildCard(RecommendationItem rec) {
    final cfg = _typeConfig[rec.type] ?? _typeConfig['overtime']!;
    final color = cfg['color'] as Color;
    final bg = cfg['bg'] as Color;
    final icon = cfg['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rec.typeLabel, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
              if (rec.suggestedDate != null)
                Text(rec.suggestedDate!, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
            ])),
            if (rec.autoApplyEligible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('تطبيق تلقائي', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
          ]),
          const SizedBox(height: 10),
          Text(rec.reason, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary, height: 1.5)),
          if (rec.suggestedHours != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.hourglass_bottom_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text('${rec.suggestedHours} ساعة إضافية', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ]),
          ],
          if (rec.suggestedDays != null && rec.type != 'overtime') ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text('${rec.suggestedDays} ${rec.suggestedDays == 1 ? 'يوم' : 'أيام'}', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ]),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _apply(rec),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: Icon(rec.isNotificationOnly ? Icons.notifications_outlined : Icons.check_rounded, size: 16),
                label: Text(rec.actionLabel, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _dismiss(rec),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                side: BorderSide(color: Colors.grey.shade300),
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('تجاهل', style: GoogleFonts.cairo(fontSize: 13)),
            ),
          ]),
        ]),
      ),
    );
  }
}
