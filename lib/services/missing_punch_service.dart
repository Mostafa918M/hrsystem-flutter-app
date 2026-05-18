import 'package:dio/dio.dart';
import '../core/api_client.dart';

class MissingPunchRequest {
  final String id;
  final String date;
  final String type; // check_in | check_out | both
  final String? requestedCheckIn;
  final String? requestedCheckOut;
  final String reason;
  final String status; // pending | approved | rejected
  final String? reviewNote;
  final String createdAt;

  MissingPunchRequest({
    required this.id,
    required this.date,
    required this.type,
    this.requestedCheckIn,
    this.requestedCheckOut,
    required this.reason,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory MissingPunchRequest.fromJson(Map<String, dynamic> json) {
    return MissingPunchRequest(
      id: json['_id'] ?? '',
      date: json['date'] ?? '',
      type: json['type'] ?? 'check_in',
      requestedCheckIn: json['requestedCheckIn'],
      requestedCheckOut: json['requestedCheckOut'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      reviewNote: json['reviewNote'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class MissingPunchService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MissingPunchRequest>> getMyRequests() async {
    try {
      final response = await _apiClient.dio.get('missing-punches/my');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((e) => MissingPunchRequest.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submit({
    required String date,
    required String type,
    String? requestedCheckIn,
    String? requestedCheckOut,
    required String reason,
  }) async {
    try {
      final data = <String, dynamic>{
        'date': date,
        'type': type,
        'reason': reason,
      };
      if (requestedCheckIn != null) data['requestedCheckIn'] = requestedCheckIn;
      if (requestedCheckOut != null) data['requestedCheckOut'] = requestedCheckOut;

      final response = await _apiClient.dio.post('missing-punches', data: data);
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
        'message': response.data['message'] ?? 'تم تقديم الطلب بنجاح',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'فشل تقديم الطلب',
      };
    } catch (_) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}
