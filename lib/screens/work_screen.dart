import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import 'check_in_screen.dart';

class WorkScreen extends StatelessWidget {
  final Map<String, dynamic>? attendanceData;

  const WorkScreen({super.key, this.attendanceData});

  @override
  Widget build(BuildContext context) {
    final bool isPending = attendanceData?['earlyCheckout']?['status'] == 'pending';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("جلسة العمل", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        leading: IconButton(
          tooltip: 'الرئيسية',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (isPending ? Colors.amber.shade700 : AppTheme.primaryColor).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending ? Icons.hourglass_top_rounded : Icons.timer_outlined, 
                      size: 64, 
                      color: isPending ? Colors.amber.shade700 : AppTheme.primaryColor
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPending ? 'في انتظار موافقة الإدارة' : 'أنت في العمل الآن',
                    style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPending 
                        ? 'تم إرسال طلب الانصراف المبكر للإدارة' 
                        : 'جلستك نشطة منذ بداية يوم العمل',
                    style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!isPending)
                    ElevatedButton(
                      onPressed: () => _handleCheckOut(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.red.withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.exit_to_app_rounded),
                          const SizedBox(width: 12),
                          Text('تسجيل الانصراف (مغادرة)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'يرجى الانتظار لحين مراجعة الموارد البشرية لطلب الانصراف المبكر الخاص بك.',
                              style: GoogleFonts.cairo(color: Colors.brown.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildFeaturePlaceholder('المهام والمشاريع', Icons.assignment_outlined),
            const SizedBox(height: 16),
            _buildFeaturePlaceholder('محادثة الفريق', Icons.chat_bubble_outline_rounded),
            const SizedBox(height: 16),
            _buildFeaturePlaceholder('التقرير اليومي', Icons.analytics_outlined),
          ],
        ),
      ),
    );
  }

  void _handleCheckOut(BuildContext context) {
    final now = DateTime.now();
    final bool isEarly = now.hour < 17;

    if (isEarly) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تنبيه انصراف مبكر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
          content: Text(
            'أنت تحاول الانصراف قبل مواعيد العمل الرسمية (05:00 مساءً).\n\nهل أنت متأكد من رغبتك في المغادرة الآن؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600, foregroundColor: Colors.white),
              child: Text('نعم، انصراف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen()));
    }
  }

  Widget _buildFeaturePlaceholder(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 22),
          ),
          const SizedBox(width: 16),
          Text(title, style: GoogleFonts.cairo(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('قريباً', style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
