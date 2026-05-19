import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';
import 'check_in_screen.dart';
import 'work_screen.dart';
import 'profile_screen.dart';
import 'attendance_report_screen.dart';
import 'salary_screen.dart';
import 'leave_request_screen.dart';
import 'loan_request_screen.dart';
import 'overtime_request_screen.dart';
import 'expense_request_screen.dart';
import 'vacation_advance_screen.dart';
import 'encashment_request_screen.dart';
import 'notifications_screen.dart';
import 'approval_hub_screen.dart';
import 'my_team_screen.dart';
import 'my_schedule_screen.dart';
import 'recommendations_screen.dart';
import '../services/recommendation_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final RecommendationService _recommendationService = RecommendationService();
  Map<String, dynamic>? _todayStatus;
  bool _isLoadingStatus = true;
  int _pendingRecsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
    } catch (_) {}
    final status = await _attendanceService.getTodayStatus();
    final recs = await _recommendationService.getMy();
    if (mounted) {
      setState(() {
        _todayStatus = status;
        _pendingRecsCount = recs.length;
        _isLoadingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final firstName = user?.name.split(' ')[0] ?? 'الموظف';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'أهلاً، $firstName 👋',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 70,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              backgroundColor: AppTheme.primaryColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user?.enabledFeatures['attendance'] != false) ...[
                      _buildAttendanceCard(context),
                      const SizedBox(height: 24),
                    ],
                    _buildQuickActionsRow(user),
                    const SizedBox(height: 24),
                    if (user?.role == 'manager') ...[
                      _buildSectionHeader('مدير القسم'),
                      const SizedBox(height: 12),
                      _buildServiceTile(
                        context, 
                        Icons.fact_check_outlined, 
                        'مركز الموافقات', 
                        'مراجعة واعتماد طلبات الموظفين', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalHubScreen()))
                      ),
                      const SizedBox(height: 10),
                      _buildServiceTile(
                        context, 
                        Icons.groups_outlined, 
                        'فريقي', 
                        'عرض موظفي القسم', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTeamScreen()))
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionHeader('خدمات سريعة'),
                    const SizedBox(height: 12),

                    if (user?.enabledFeatures['leaveRequests'] != false) ...[
                      _buildServiceTile(context, Icons.calendar_month_outlined, 'طلب إجازة', 'إدارة طلبات الإجازة وتتبع الأرصدة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['loans'] != false) ...[
                      _buildServiceTile(context, Icons.payments_outlined, 'طلب سلفة', 'تقديم ومتابعة طلبات السلف المالية', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanRequestScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['vacationAdvances'] != false) ...[
                      _buildServiceTile(context, Icons.beach_access, 'سلفة إجازة (Vacation Advance)', 'صرف راتب الإجازة مقدماً قبل الخروج', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VacationAdvanceScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['leaveEncashments'] != false) ...[
                      _buildServiceTile(context, Icons.handshake_outlined, 'تسييل الإجازات ونهاية الخدمة', 'طلب صرف رصيد الإجازات ومكافأة نهاية الخدمة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EncashmentRequestScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['overtimeRequests'] != false) ...[
                      _buildServiceTile(context, Icons.more_time_rounded, 'طلب عمل إضافي', 'تسجيل ساعات العمل الإضافي المنجزة', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OvertimeRequestScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['companyExpenses'] != false) ...[
                      _buildServiceTile(context, Icons.receipt_long_rounded, 'طلب تعويض مصاريف', 'استرداد مصاريف السفر أو المستلزمات وغيرها', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseRequestScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['salarySlips'] != false) ...[
                      _buildServiceTile(context, Icons.receipt_long_outlined, 'كشف الراتب', 'عرض بيانات الراتب الشهري بالتفصيل', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen()))),
                      const SizedBox(height: 10),
                    ],
                    if (user?.enabledFeatures['attendance'] != false) ...[
                      _buildServiceTile(context, Icons.bar_chart_rounded, 'تقرير الحضور', 'متابعة سجل الحضور والانصراف', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportScreen()))),
                      const SizedBox(height: 10),
                    ],
                    _buildServiceTile(context, Icons.calendar_view_week_rounded, 'جدولي الأسبوعي', 'عرض الوردية المخصصة لكل يوم من الأسبوع', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyScheduleScreen()))),
                    const SizedBox(height: 10),
                    _buildServiceTileWithBadge(context, Icons.auto_awesome_rounded, 'التوصيات الذكية', 'اقتراحات عمل إضافي وإجازات مبنية على الحضور', _pendingRecsCount, () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationsScreen())); _loadStatus(); }),
                    const SizedBox(height: 10),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    final bool isCheckedIn = _todayStatus != null &&
        _todayStatus!['checkIn'] != null &&
        _todayStatus!['checkIn']['time'] != null;
    final bool isCheckedOut = _todayStatus != null &&
        _todayStatus!['checkOut'] != null &&
        _todayStatus!['checkOut']['time'] != null;

    final bool isEarlyCheckoutPending = _todayStatus != null &&
        _todayStatus!['earlyCheckout'] != null &&
        _todayStatus!['earlyCheckout']['isRequested'] == true &&
        _todayStatus!['earlyCheckout']['status'] == 'pending';

    final bool isEarlyCheckoutRejected = _todayStatus != null &&
        _todayStatus!['earlyCheckout'] != null &&
        _todayStatus!['earlyCheckout']['isRequested'] == true &&
        _todayStatus!['earlyCheckout']['status'] == 'rejected';

    final bool isEffectivelyCheckedOut = isCheckedOut;

    String statusText = 'مستعد للعمل؟';
    String subText = 'سجّل حضورك لبدء يوم العمل';
    IconData statusIcon = Icons.wb_sunny_outlined;
    Color cardColor = AppTheme.primaryColor;

    if (isCheckedIn && !isEffectivelyCheckedOut) {
      if (isEarlyCheckoutPending) {
        statusText = 'في انتظار الموافقة';
        subText = 'تم إرسال طلب الانصراف المبكر للإدارة';
        statusIcon = Icons.hourglass_top_rounded;
        cardColor = AppTheme.secondaryColor;
      } else if (isEarlyCheckoutRejected) {
        statusText = 'أنت في العمل الآن';
        subText = 'تم رفض الانصراف المبكر. الجلسة نشطة.';
        statusIcon = Icons.work_rounded;
        cardColor = AppTheme.primaryColor;
      } else {
        statusText = 'أنت في العمل الآن';
        subText = 'الجلسة نشطة';
        statusIcon = Icons.work_rounded;
        cardColor = AppTheme.secondaryColor;
      }
    } else if (isEffectivelyCheckedOut) {
      statusText = 'انتهى يوم العمل!';
      subText = 'أراك غداً 😊';
      statusIcon = Icons.check_circle_rounded;
      cardColor = AppTheme.primaryColor;
    } else if (_todayStatus?['status'] == 'on_leave') {
      statusText = 'أنت في إجازة حالياً';
      subText = 'استمتع بوقتك! 😊';
      statusIcon = Icons.beach_access_rounded;
      cardColor = AppTheme.primaryColor;
    }

    // Late notification
    final now = DateTime.now();
    final bool isOnLeave = _todayStatus?['status'] == 'on_leave';
    if (!_isLoadingStatus && !isCheckedIn && !isCheckedOut && !isOnLeave && now.hour >= 11) {
      _showLateNotificationOnce();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoadingStatus
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : Column(
              children: [
                Icon(statusIcon, color: Colors.white.withOpacity(0.9), size: 48),
                const SizedBox(height: 12),
                Text(
                  statusText,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!isEffectivelyCheckedOut && _todayStatus?['status'] != 'on_leave')
                  ElevatedButton(
                    onPressed: () async {
                      if (isCheckedIn) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WorkScreen(attendanceData: _todayStatus)),
                        );
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckInScreen()),
                        );
                      }
                      _loadStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: cardColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isCheckedIn ? Icons.work_outline : Icons.qr_code_scanner),
                        const SizedBox(width: 8),
                        Text(
                          isCheckedIn 
                              ? (isEarlyCheckoutPending ? 'متابعة حالة الطلب' : 'متابعة جلسة العمل')
                              : 'تسجيل الحضور الآن',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                if (isEffectivelyCheckedOut)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'تم تسجيل الحضور ✓',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildQuickActionsRow(user) {
    return Row(
      children: [
        if (user?.enabledFeatures['attendance'] != false) ...[
          _buildQuickAction(context, Icons.fingerprint_rounded, 'الحضور', AppTheme.primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceReportScreen()))),
          const SizedBox(width: 12),
        ],
        if (user?.enabledFeatures['leaveRequests'] != false) ...[
          _buildQuickAction(context, Icons.event_note_rounded, 'الإجازات', AppTheme.secondaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveRequestScreen()))),
          const SizedBox(width: 12),
        ],
        _buildQuickAction(context, Icons.calendar_view_week_rounded, 'جدولي', const Color(0xFF4338CA), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyScheduleScreen()))),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildServiceTileWithBadge(BuildContext context, IconData icon, String title, String subtitle, int badgeCount, VoidCallback onTap) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildServiceTile(context, icon, title, subtitle, onTap),
        if (badgeCount > 0)
          Positioned(
            top: 8, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(10)),
              child: Text('$badgeCount', style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          textAlign: TextAlign.start,
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary),
          textAlign: TextAlign.start,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }

  bool _lateNotified = false;
  void _showLateNotificationOnce() {
    if (_lateNotified) return;
    _lateNotified = true;

    NotificationService.showNotification(
      id: 1,
      title: 'تنبيه حضور',
      body: 'أنت متأخر عن موعد العمل! يرجى تسجيل الحضور فوراً.',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.notification_important_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Text('تنبيه حضور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'أنت متأخر عن موعد العمل! يرجى تسجيل الحضور فوراً لتجنب تطبيق لائحة الجزاءات.',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('فهمت', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }
}
