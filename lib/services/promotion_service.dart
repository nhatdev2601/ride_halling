import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promotion_model.dart';
import 'auth_service.dart'; // Import cái service lấy token của mày
import '../config/config.dart';
class PromotionService {
  // Nhớ đổi IP nếu chạy máy thật (192.168.1.x)
  static final String baseUrl = '${AppConfig.baseUrl}/api/promotions'; 
  final AuthService _authService = AuthService();

  Future<List<Promotion>> getActivePromotions() async {
    try {
      // 1. Lấy token (User phải đăng nhập mới xem được mã)
      String? token = await _authService.getAccessToken();
      if (token == null) return [];

      // 2. Gọi API
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Promotion.fromJson(json)).toList();
      } else {
        print('Lỗi lấy khuyến mãi: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception PromotionService: $e');
      return [];
    }
  }
}