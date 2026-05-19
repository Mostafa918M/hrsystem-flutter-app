import 'package:dio/dio.dart';
import '../core/api_client.dart';

class RecommendationItem {
  final String id;
  final String type; // overtime | compensatory_leave | time_off
  final String? suggestedDate;
  final double? suggestedHours;
  final int? suggestedDays;
  final String reason;
  final bool autoApplyEligible;
  final String status;

  RecommendationItem({
    required this.id,
    required this.type,
    this.suggestedDate,
    this.suggestedHours,
    this.suggestedDays,
    required this.reason,
    required this.autoApplyEligible,
    required this.status,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'overtime',
      suggestedDate: json['suggestedDate'],
      suggestedHours: json['suggestedHours'] != null ? (json['suggestedHours'] as num).toDouble() : null,
      suggestedDays: json['suggestedDays'],
      reason: json['reason'] ?? '',
      autoApplyEligible: json['autoApplyEligible'] == true,
      status: json['status'] ?? 'pending',
    );
  }

  String get typeLabel {
    switch (type) {
      case 'overtime':           return 'عمل إضافي';
      case 'compensatory_leave': return 'إجازة تعويضية';
      case 'time_off':           return 'أخذ استراحة';
      case 'excessive_lateness': return 'تكرار التأخر';
      case 'missing_document':   return 'وثيقة مفقودة';
      default: return type;
    }
  }

  String get actionLabel {
    if (type == 'excessive_lateness' || type == 'missing_document') return 'إبلاغ الموظف';
    return 'تطبيق';
  }

  bool get isNotificationOnly => type == 'excessive_lateness' || type == 'missing_document';
}

class RecommendationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<RecommendationItem>> getMy() async {
    try {
      final response = await _apiClient.dio.get('recommendations/my');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((e) => RecommendationItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> apply(String id) async {
    try {
      final response = await _apiClient.dio.post('recommendations/$id/apply');
      return {
        'success': response.statusCode == 200,
        'message': response.data['message'] ?? 'تم تطبيق التوصية',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل التطبيق'};
    } catch (_) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> dismiss(String id) async {
    try {
      final response = await _apiClient.dio.post('recommendations/$id/dismiss');
      return {
        'success': response.statusCode == 200,
        'message': response.data['message'] ?? 'تم تجاهل التوصية',
      };
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'فشل التجاهل'};
    } catch (_) {
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}
