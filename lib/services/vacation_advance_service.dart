import 'package:dio/dio.dart';
import '../core/api_client.dart';

class VacationAdvanceService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> calculateAdvance({
    required String employeeId,
    required String leaveId,
    int monthsCovered = 1,
  }) async {
    try {
      final response = await _apiClient.dio.post('vacation-advance/calculate', data: {
        'employeeId': employeeId,
        'leaveId': leaveId,
        'monthsCovered': monthsCovered,
      });
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> requestAdvance({
    required String employeeId,
    required String leaveId,
    int monthsCovered = 1,
  }) async {
    try {
      final response = await _apiClient.dio.post('vacation-advance', data: {
        'employeeId': employeeId,
        'leaveId': leaveId,
        'monthsCovered': monthsCovered,
      });
      if (response.statusCode == 201) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getEmployeeAdvances(String employeeId) async {
    try {
      final response = await _apiClient.dio.get('vacation-advance/employee/$employeeId');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
