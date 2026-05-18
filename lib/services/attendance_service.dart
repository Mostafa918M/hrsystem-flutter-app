import 'package:dio/dio.dart';
import '../core/api_client.dart';
import 'package:geolocator/geolocator.dart';

class WorkLocationSite {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  WorkLocationSite({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  factory WorkLocationSite.fromJson(Map<String, dynamic> json) {
    return WorkLocationSite(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200.0,
    );
  }
}

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

  /// Returns all active work locations for the tenant.
  /// Falls back to the tenant's single officeLocation if none are configured.
  Future<List<WorkLocationSite>> getWorkLocations() async {
    try {
      final response = await _apiClient.dio.get('work-locations');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> raw = response.data['data'];
        final active = raw
            .where((loc) => loc['isActive'] == true)
            .map((loc) => WorkLocationSite.fromJson(loc))
            .toList();

        if (active.isNotEmpty) return active;
      }
    } catch (_) {}

    // Fallback: single office location from tenant settings
    try {
      final response = await _apiClient.dio.get('tenants/me');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final office = response.data['data']['officeLocation'];
        if (office != null && office['lat'] != null) {
          return [
            WorkLocationSite(
              id: '',
              name: 'Main Office',
              lat: (office['lat'] as num).toDouble(),
              lng: (office['lng'] as num).toDouble(),
              radiusMeters: (office['radiusMeters'] as num?)?.toDouble() ?? 200.0,
            )
          ];
        }
      }
    } catch (_) {}

    return [];
  }

  /// Returns the nearest work location and whether the user is within its radius.
  /// Returns null if no work locations are configured.
  Future<({WorkLocationSite? site, double distance, bool isWithinRange})>
      resolveNearestLocation(Position userPosition) async {
    final sites = await getWorkLocations();

    if (sites.isEmpty) {
      return (site: null, distance: double.infinity, isWithinRange: false);
    }

    WorkLocationSite? nearest;
    double nearestDistance = double.infinity;

    for (final site in sites) {
      final dist = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        site.lat,
        site.lng,
      );
      if (dist < nearestDistance) {
        nearestDistance = dist;
        nearest = site;
      }
    }

    final isWithinRange = nearestDistance <= (nearest?.radiusMeters ?? 200);
    return (site: nearest, distance: nearestDistance, isWithinRange: isWithinRange);
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
      return {'success': false, 'message': 'An unexpected error occurred'};
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
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
