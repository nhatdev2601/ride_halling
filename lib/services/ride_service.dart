import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride_models.dart';
import 'auth_service.dart';

import '../config/config.dart';

class RideService {
  static const String baseUrl =
      '${AppConfig.baseUrl}/api/Rides'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5267/api/Rides'; // iOS Simulator

  final AuthService _authService = AuthService();

  // 🧮 Tính giá cước
  Future<CalculateFareResponse?> calculateFare(
    CalculateFareRequest request,
  ) async {
    try {
      print('========================================');
      print('📤 GỬI REQUEST TÍNH GIÁ');
      print('========================================');
      print('URL: $baseUrl/calculate-fare');
      print('Body: ${jsonEncode(request.toJson())}');
      print('========================================\n');

      final token = await _authService.getAccessToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/calculate-fare'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      print('========================================');
      print('📥 NHẬN RESPONSE');
      print('========================================');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('========================================\n');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CalculateFareResponse.fromJson(json);
      } else {
        print('❌ Lỗi: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return null;
    }
  }

  // 🚗 Đặt xe
  Future<CreateRideResponse?> bookRide(CreateRideRequest request) async {
    try {
      print('========================================');
      print('📤 GỬI REQUEST ĐẶT XE');
      print('========================================');
      print('URL: $baseUrl/book');
      print('Body: ${jsonEncode(request.toJson())}');
      print('========================================\n');

      final token = await _authService.getAccessToken();
      // 👇 THÊM DÒNG NÀY ĐỂ CHECK
      print('🔑 TOKEN CỦA TAO LÀ: $token'); 

      if (token == null || token.isEmpty) {
          print('❌ CHẾT MẸ RỒI, TOKEN BỊ NULL!');
          return null;
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/book'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      print('========================================');
      print('📥 NHẬN RESPONSE ĐẶT XE');
      print('========================================');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('========================================\n');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CreateRideResponse.fromJson(json);
      } else {
        print('❌ Lỗi: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return null;
    }
  }

  // 📍 Lấy thông tin ride
  Future<RideDetail?> getRide(String rideId) async {
    try {
      final token = await _authService.getAccessToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/$rideId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return RideDetail.fromJson(json);
      }
      return null;
    } catch (e) {
      print('❌ Exception: $e');
      return null;
    }
  }

  // ❌ Hủy chuyến xe
 Future<bool> cancelRide(String rideId, String reason) async {
    try {
      final token = await _authService.getAccessToken();
print('🔻 ĐANG GỌI API CANCEL CHO ID: $rideId'); 
      print('URL: $baseUrl/$rideId/cancel');
      // Gọi đúng endpoint /cancel mà controller định nghĩa
      final response = await http
          .post(
            Uri.parse('$baseUrl/$rideId/cancel'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            // Body chỉ cần gửi reason, backend tự lo status
            body: jsonEncode({'reason': reason}),
          )
          .timeout(const Duration(seconds: 10));

      print('Cancel Status: ${response.statusCode}');
      print('Cancel Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Exception: $e');
      return false;
    }
  }
  Future<List<RideHistoryItem>> getRideHistory() async {
    try {
      final token = await _authService.getAccessToken();
      
      // Gọi GET /api/Rides
      final response = await http.get(
        Uri.parse('$baseUrl'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => RideHistoryItem.fromJson(json)).toList();
      } else {
        print('❌ Lỗi lấy lịch sử: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception: $e');
      return [];
    }
  }
  Future<RideDetail?> getRideForTracking(String rideId) async {
    try {
      final token = await _authService.getAccessToken();
      
      // Gọi vào đường dẫn có đuôi /details như Backend đã viết
      final url = '$baseUrl/$rideId/details'; 
      print("🔗 Đang gọi API chi tiết (kèm SĐT): $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Parse JSON sang Model
        return RideDetail.fromJson(json);
      } else {
        print("❌ Lỗi lấy chi tiết ride: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception Tracking: $e");
      return null;
    }
  }
}
