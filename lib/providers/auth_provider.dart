import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final ApiClient _apiClient = ApiClient();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        var androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // Unique ID on Android
      } else if (Platform.isIOS) {
        var iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      } else if (Platform.isWindows) {
        var winInfo = await _deviceInfo.windowsInfo;
        return winInfo.deviceId;
      }
    } catch (e) {
      return 'unknown_device';
    }
    return 'unknown_platform';
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final deviceId = await _getDeviceId();
      
      final response = await _apiClient.dio.post('auth/login', data: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['accessToken'];
        _user = User.fromJson(data['user']);
        
        await _apiClient.storage.write(key: 'token', value: token);
        await _apiClient.storage.write(key: 'email', value: email);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Internal logout (for session conflicts or admin reset)
  Future<void> logout() async {
    await _apiClient.storage.delete(key: 'token');
    _user = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _apiClient.storage.read(key: 'token');
    if (token != null) {
      try {
        final response = await _apiClient.dio.get('auth/me');
        if (response.statusCode == 200) {
          _user = User.fromJson(response.data['data']);
          notifyListeners();
        } else {
          await logout();
        }
      } catch (e) {
        // If it's a 401/403, it means the session is invalid (likely new device login)
        await logout();
      }
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post('auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        if (_user != null) {
          _user = User(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            role: _user!.role,
            profileImage: _user!.profileImage,
            employeeId: _user!.employeeId,
            annualLeaveBalance: _user!.annualLeaveBalance,
            sickLeaveBalance: _user!.sickLeaveBalance,
            emergencyLeaveBalance: _user!.emergencyLeaveBalance,
            loans: _user!.loans,
            basicSalary: _user!.basicSalary,
            allowances: _user!.allowances,
            enabledFeatures: _user!.enabledFeatures,
            mustChangePassword: false,
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Change password error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
