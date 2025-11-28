// ✅ Trip Service (lib/services/trip_service.dart - Mới, singleton như AuthService)
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/ride_models.dart';
import '../config/config.dart'; // AppConfig.baseUrl
import 'auth_service.dart'; // Để lấy token
import 'location_service_driver.dart'; // Để lấy vị trí nếu cần

class TripService {
  // Singleton pattern (như AuthService)
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  // Base URL cho driver trips (giả sử /api/driver)
  static const String baseUrl = '${AppConfig.baseUrl}/api/driver';

  // Get headers with auth (tương tự AuthService)
  Future<Map<String, String>> _getHeaders() async {
    final auth = AuthService();
    await auth.loadSavedAuth(); // Đảm bảo token loaded
    final headers = {'Content-Type': 'application/json'};
    if (auth.token != null) {
      headers['Authorization'] = 'Bearer ${auth.token}';
    }
    return headers;
  }

  // ✅ Lấy chuyến gần (HomeScreen) - GET /api/driver/trips/nearby?lat=...&lng=...
  Future<List<Ride>> getNearbyTrips(
    double lat,
    double lng, {
    double radiusKm = 5.0,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/trips/nearby').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'radiusKm': radiusKm.toString(),
        },
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      print('Nearby Trips Response Status: ${response.statusCode}');
      print('Nearby Trips Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Ride.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Refresh token nếu 401
        await AuthService().refreshAccessToken();
        return getNearbyTrips(lat, lng, radiusKm: radiusKm); // Retry
      } else {
        throw Exception('Lỗi lấy chuyến gần: ${response.body}');
      }
    } catch (e) {
      print('Get nearby trips error: $e');
      return [];
    }
  }

  // ✅ Lấy chuyến đang diễn ra (OngoingTripsScreen) - GET /api/driver/trips/ongoing
  Future<List<Ride>> getOngoingTrips() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/trips/ongoing'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('Ongoing Trips Response Status: ${response.statusCode}');
      print('Ongoing Trips Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Ride.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await AuthService().refreshAccessToken();
        return getOngoingTrips(); // Retry
      } else {
        throw Exception('Lỗi lấy chuyến đang diễn ra: ${response.body}');
      }
    } catch (e) {
      print('Get ongoing trips error: $e');
      return [];
    }
  }

  // ✅ Chấp nhận chuyến - POST /api/driver/trips/{rideId}/accept
  Future<Ride?> acceptTrip(String rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse('$baseUrl/trips/$rideId/accept'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('Accept Trip Response Status: ${response.statusCode}');
      print('Accept Trip Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return Ride.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await AuthService().refreshAccessToken();
        return acceptTrip(rideId); // Retry
      } else {
        throw Exception('Lỗi chấp nhận chuyến: ${response.body}');
      }
    } catch (e) {
      print('Accept trip error: $e');
      return null;
    }
  }

  // ✅ Kết thúc chuyến - POST /api/driver/trips/{rideId}/end
  Future<bool> endTrip(String rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse('$baseUrl/trips/$rideId/end'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('End Trip Response Status: ${response.statusCode}');
      print('End Trip Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await AuthService().refreshAccessToken();
        return endTrip(rideId); // Retry
      } else {
        throw Exception('Lỗi kết thúc chuyến: ${response.body}');
      }
    } catch (e) {
      print('End trip error: $e');
      return false;
    }
  }

  // ✅ Fake vị trí tài xế (tích hợp LocationServiceDriver có sẵn)
  Future<bool> teleportDriverToLocation(LatLng location) async {
    // Gọi từ location_service_driver.dart
    final locationServiceDriver =
        LocationServiceDriver(); // Import và instance nếu cần
    return await locationServiceDriver.teleportDriverToLocation(location);
  }
}
