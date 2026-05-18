import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../core/api_client.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  static Future<void> init() async {
    // Request permission for Android 13+
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click if needed
      },
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      channelDescription: 'Notifications for attendance and work schedule',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id, 
      title: title, 
      body: body, 
      notificationDetails: platformDetails,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('notifications');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiClient.dio.put('notifications/$id/read');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.put('notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

