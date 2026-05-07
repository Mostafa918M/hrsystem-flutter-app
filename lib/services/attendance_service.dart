import 'package:dio/dio.dart';
import '../core/api_client.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>?> getTodayStatus() async {
    try {
      final response = await _apiClient.dio.get('attendance/today-status');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOfficeLocation() async {
    try {
      final response = await _apiClient.dio.get('tenant/me');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data']['officeLocation'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> checkIn(String qrToken) async {
    try {
      Position position = await determinePosition();

      final response = await _apiClient.dio.post('attendance/check-in', data: {
        'qrToken': qrToken,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        }
      });

      return {
        'success': response.statusCode == 200,
        'message': response.data['message'] ?? 'Check-in successful',
        'data': response.data['data']
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Check-in failed: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred'
      };
    }
  }

  Future<Map<String, dynamic>> checkOut(String qrToken, {String? note}) async {
    try {
      Position position = await determinePosition();

      final data = {
        'qrToken': qrToken,
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
        }
      };
      
      if (note != null && note.isNotEmpty) {
        data['note'] = note;
      }

      final response = await _apiClient.dio.post('attendance/check-out', data: data);

      return {
        'success': response.statusCode == 200,
        'message': response.data['message'] ?? 'Check-out successful',
        'data': response.data['data']
      };
    } on DioException catch (e) {
      final responseData = e.response?.data ?? {};
      return {
        'success': false,
        'message': responseData['message'] ?? 'Check-out failed: ${e.message}',
        'isEarlyCheckout': responseData['isEarlyCheckout'] == true,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred'
      };
    }
  }
}
