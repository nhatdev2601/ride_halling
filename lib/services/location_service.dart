import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static const String GOONG_API_KEY = 'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ';

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  //  Lấy vị trí hiện tại
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Kiểm tra GPS có bật không
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.error('Vui lòng bật GPS để lấy vị trí.');
      }

      // Kiểm tra quyền truy cập
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.error('Ứng dụng bị từ chối quyền truy cập vị trí.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error('Ứng dụng bị từ chối vĩnh viễn quyền truy cập vị trí.');
      }

      // Lấy vị trí
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng latLng = LatLng(position.latitude, position.longitude);
      
      // Reverse geocode để lấy địa chỉ
      String address = await reverseGeocode(latLng);

      return LocationResult.success(latLng, address);
    } catch (e) {
      return LocationResult.error('Lỗi lấy vị trí: ${e.toString()}');
    }
  }

  //  Geocode: Chuyển địa chỉ → Tọa độ
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    try {
      final String url =
          'https://rsapi.goong.io/geocode?address=${Uri.encodeComponent(address)}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['results'] != null && json['results'].isNotEmpty) {
          final location = json['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print(' Lỗi geocode: $e');
    }
    return null;
  }

  //  Reverse Geocode: Chuyển Tọa độ → Địa chỉ
  Future<String> reverseGeocode(LatLng position) async {
    try {
      final String url =
          'https://rsapi.goong.io/Geocode?latlng=${position.latitude},${position.longitude}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['results'] != null && json['results'].isNotEmpty) {
          return json['results'][0]['formatted_address'] ?? 'Vị trí hiện tại';
        }
      }
    } catch (e) {
      print(' Lỗi reverse geocode: $e');
    }
    return 'Vị trí hiện tại';
  }

  //  Lấy gợi ý địa điểm
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String input) async {
    if (input.isEmpty) return [];

    try {
      final String url =
          'https://rsapi.goong.io/Place/AutoComplete?input=${Uri.encodeComponent(input)}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['predictions'] != null) {
          return (json['predictions'] as List)
              .map((e) => PlaceSuggestion.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print(' Lỗi lấy gợi ý: $e');
    }
    return [];
  }

  //  Lấy tọa độ từ Place ID
  Future<LatLng?> getLatLngFromPlaceId(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final String url =
          'https://rsapi.goong.io/Place/Detail?place_id=${Uri.encodeComponent(placeId)}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['result'] != null && json['result']['geometry'] != null) {
          final location = json['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print(' Lỗi lấy Place ID: $e');
    }
    return null;
  }

  //  Tính khoảng cách giữa 2 điểm (km)
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert to km
  }
}

// 📦 Model cho kết quả lấy vị trí
class LocationResult {
  final bool success;
  final LatLng? location;
  final String? address;
  final String? errorMessage;

  LocationResult._({
    required this.success,
    this.location,
    this.address,
    this.errorMessage,
  });

  factory LocationResult.success(LatLng location, String address) {
    return LocationResult._(
      success: true,
      location: location,
      address: address,
    );
  }

  factory LocationResult.error(String message) {
    return LocationResult._(
      success: false,
      errorMessage: message,
    );
  }
}

// 📦 Model cho gợi ý địa điểm
class PlaceSuggestion {
  final String description;
  final String placeId;
  final String? structuredFormatting;

  PlaceSuggestion({
    required this.description,
    required this.placeId,
    this.structuredFormatting,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      description: json['description'] ?? '',
      placeId: json['place_id'] ?? '',
      structuredFormatting: json['structured_formatting']?['main_text'],
    );
  }
}