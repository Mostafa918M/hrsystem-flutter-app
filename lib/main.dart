import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'core/app_theme.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'services/attendance_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/change_password_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final ApiClient apiClient = ApiClient();
      final String? token = await apiClient.storage.read(key: 'token');
      if (token == null) {
        return Future.value(true);
      }

      final status = await AttendanceService().getTodayStatus();
      final bool isCheckedIn = status != null &&
          status['checkIn'] != null &&
          status['checkIn']['time'] != null;
      final bool isCheckedOut = status != null &&
          status['checkOut'] != null &&
          status['checkOut']['time'] != null;
      final bool isOnLeave = status != null && status['status'] == 'on_leave';

      final now = DateTime.now();
      if (!isCheckedIn && !isCheckedOut && !isOnLeave && now.hour >= 11) {
        await NotificationService.init();
        await NotificationService.showNotification(
          id: 1,
          title: 'تنبيه حضور',
          body: 'أنت متأخر عن موعد العمل! يرجى تسجيل الحضور فوراً.',
        );
      } else if (isCheckedIn) {
        await NotificationService.init();
        await NotificationService.cancelNotification(1);
      }
    } catch (_) {}
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  await Workmanager().registerPeriodicTask(
    "late_attendance_check_task",
    "lateAttendanceCheckTask",
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: MaterialApp(
        title: 'نظام الموارد البشرية',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [
          Locale('ar', 'EG'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              if (auth.user?.mustChangePassword == true) {
                return const ChangePasswordScreen();
              }
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
        },
      ),
    );
  }
}
