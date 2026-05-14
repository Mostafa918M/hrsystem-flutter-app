import 'package:dio/dio.dart';
import '../core/api_client.dart';

class EncashmentService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> requestVacationEncashment({
    required String employeeId,
    required int unusedDays,
  }) async {
    try {
      final response = await _apiClient.dio.post('encashments/vacation', data: {
        'employeeId': employeeId,
        'unusedDays': unusedDays,
      });
      if (response.statusCode == 201) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> requestSTBEncashment({
    required String employeeId,
  }) async {
    try {
      final response = await _apiClient.dio.post('encashments/stb', data: {
        'employeeId': employeeId,
      });
      if (response.statusCode == 201) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getEmployeeEncashments(String employeeId) async {
    try {
      final response = await _apiClient.dio.get('encashments/employee/$employeeId');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
