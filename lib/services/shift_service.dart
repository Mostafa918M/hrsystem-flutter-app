import '../core/api_client.dart';

class DaySchedule {
  final String date;
  final String dayName;
  final ShiftInfo? shift;

  DaySchedule({required this.date, required this.dayName, this.shift});

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      date: json['date'] ?? '',
      dayName: json['dayName'] ?? '',
      shift: json['shift'] != null ? ShiftInfo.fromJson(json['shift']) : null,
    );
  }
}

class ShiftInfo {
  final String id;
  final String name;
  final String type;
  final String? startTime;
  final String? endTime;
  final List<Map<String, String>> intervals;
  final int? flexibleHours;
  final int gracePeriodMins;

  ShiftInfo({
    required this.id,
    required this.name,
    required this.type,
    this.startTime,
    this.endTime,
    this.intervals = const [],
    this.flexibleHours,
    this.gracePeriodMins = 15,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> ivs = [];
    if (json['intervals'] != null) {
      ivs = (json['intervals'] as List)
          .map((iv) => {'startTime': iv['startTime'].toString(), 'endTime': iv['endTime'].toString()})
          .toList();
    }
    return ShiftInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'regular',
      startTime: json['startTime'],
      endTime: json['endTime'],
      intervals: ivs,
      flexibleHours: json['flexibleHours'],
      gracePeriodMins: json['gracePeriodMins'] ?? 15,
    );
  }

  String get displayHours {
    if (type == 'flexible') return '${flexibleHours ?? 8}h flexible';
    if (type == 'split' && intervals.isNotEmpty) {
      return intervals.map((iv) => '${iv['startTime']} → ${iv['endTime']}').join('  |  ');
    }
    if (startTime != null && endTime != null) return '$startTime → $endTime';
    return '';
  }
}

class ShiftService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DaySchedule>> getMySchedule() async {
    try {
      final response = await _apiClient.dio.get('shifts/me');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> raw = response.data['data'];
        return raw.map((d) => DaySchedule.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
