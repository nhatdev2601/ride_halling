import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/config.dart'; // Import file config chứa baseUrl

class LocationServiceDriver {
  //  CHÚ Ý: API này nằm ở SimulationController, đường dẫn khác với Rides
  // Nếu mày dùng Ngrok thì nó là: https://.../api/simulation
  static const String simulationUrl = '${AppConfig.baseUrl}/api/simulation';

  // 👻 Hàm gọi API Fake vị trí tài xế
  Future<bool> teleportDriverToLocation(LatLng location) async {
    try {
      print('========================================');
      print('👻 GỬI REQUEST FAKE VỊ TRÍ TÀI XẾ');
      print('URL: $simulationUrl/update-location-fake');
      print('Lat/Lng: ${location.latitude}, ${location.longitude}');
      print('========================================');

      final response = await http
          .post(
            Uri.parse('$simulationUrl/update-location-fake'),
            headers: {
              'Content-Type': 'application/json',
              // API này tao để AllowAnonymous nên không cần Token
              // Nhưng nếu sau này cần thì cứ thêm 'Authorization': 'Bearer $token'
            },
            body: jsonEncode({
              'latitude': location.latitude,
              'longitude': location.longitude,
              'address': 'Vị trí khách hàng (Fake)',
            }),
          )
          .timeout(const Duration(seconds: 10));

      print(' RESPONSE FAKE VỊ TRÍ: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(' Đã dời tài xế thành công!');
        return true;
      } else {
        print(' Lỗi fake vị trí: ${response.body}');
        return false;
      }
    } catch (e) {
      print(' Exception fake vị trí: $e');
      return false;
    }
  }

  Future<bool> teleportDriverToPickup(String rideId) async {
    try {
      final String url = '$simulationUrl/teleport-to-pickup/$rideId';

      print('🚀 [Flutter] Đang gọi Teleport Driver...');
      print(' URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token' // Nếu cần token thì bỏ comment
        },
      );

      if (response.statusCode == 200) {
        print(' [Flutter] Teleport thành công! Xe đã nhảy tới gần điểm đón.');
        return true;
      } else {
        print(
          ' [Flutter] Lỗi Teleport: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print(' [Flutter] Exception Teleport: $e');
      return false;
    }
  }
}
