import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ride_models.dart';
import '../models/EarningsSummary_model.dart';
import '../config/config.dart';
import 'auth_service.dart';

class EarningsService {
  // Singleton pattern
  static final EarningsService _instance = EarningsService._internal();
  factory EarningsService() => _instance;
  EarningsService._internal();

  static const String baseUrl = '${AppConfig.baseUrl}/api/driver';

  Future<Map<String, String>> _getHeaders() async {
    final auth = AuthService();
    await auth.loadSavedAuth();
    final headers = {'Content-Type': 'application/json'};
    if (auth.token != null) {
      headers['Authorization'] = 'Bearer ${auth.token}';
    }
    return headers;
  }

  // ✅ Lấy thu nhập - GET /api/driver/earnings?fromDate=...&toDate=...
  Future<EarningsSummary> getEarnings({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/earnings').replace(
        queryParameters: {
          if (fromDate != null)
            'fromDate': fromDate.toIso8601String().split('T')[0],
          if (toDate != null) 'toDate': toDate.toIso8601String().split('T')[0],
        },
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      print('Earnings Response Status: ${response.statusCode}');
      print('Earnings Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return EarningsSummary.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await AuthService().refreshAccessToken();
        return getEarnings(fromDate: fromDate, toDate: toDate); // Retry
      } else {
        throw Exception('Lỗi lấy thu nhập: ${response.body}');
      }
    } catch (e) {
      print('Get earnings error: $e');
      return EarningsSummary.empty();
    }
  }
}
