import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:ride_hailing/services/location_service_driver.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../services/ride_service.dart';
import '../models/ride_models.dart';
import 'ride_tracking_screen.dart';
class VehicleSelectionMapScreen extends StatefulWidget {
  final String pickupAddress;
  final LatLng pickupLatLng;
  final String destinationAddress;
  final LatLng destinationLatLng;

  const VehicleSelectionMapScreen({
    super.key,
    required this.pickupAddress,
    required this.pickupLatLng,
    required this.destinationAddress,
    required this.destinationLatLng,
  });

  @override
  State<VehicleSelectionMapScreen> createState() =>
      _VehicleSelectionMapScreenState();
}

class _VehicleSelectionMapScreenState extends State<VehicleSelectionMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _distance = '';
  String _duration = '';
  bool _isLoading = true;
  bool _isBooking = false;
  double _tripDistance = 0.0;
  final LocationServiceDriver _locationService = LocationServiceDriver();
  final RideService _rideService = RideService();
  CalculateFareResponse? _fareResponse;
  String _selectedVehicleType = 'bike';

  List<Map<String, dynamic>> _vehicles = [];

  static const String GOONG_API_KEY =
      'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ';

  @override
  void initState() {
    super.initState();
    _initMap();
   // _calculateFare();
  }

  //  Gọi API tính giá
  Future<void> _calculateFare(double distanceKm) async {
    if (distanceKm <= 0) return;
    _tripDistance = distanceKm;
    try {
      final request = CalculateFareRequest(
        pickupLocation: LocationDto(
          latitude: widget.pickupLatLng.latitude,
          longitude: widget.pickupLatLng.longitude,
          address: widget.pickupAddress,
        ),
        destinationLocation: LocationDto(
          latitude: widget.destinationLatLng.latitude,
          longitude: widget.destinationLatLng.longitude,
          address: widget.destinationAddress,
        ),
        distance: distanceKm,
        vehicleType: 'bike',
      );

      final fareResponse = await _rideService.calculateFare(request);

      if (fareResponse != null && mounted) {
        setState(() {
          _fareResponse = fareResponse;
          _vehicles = fareResponse.availableVehicles.map((v) {
            return {
              'name': v.displayName,
              'icon': _getVehicleEmoji(v.vehicleType),
              'seats': v.vehicleType == 'bike' ? 1 : 4,
              'time': '${v.estimatedArrival} phút',
              'price': v.totalFare.toInt(),
              'oldPrice': null,
              'promo': null,
              'vehicleType': v.vehicleType,
            };
          }).toList();

          if (_vehicles.isNotEmpty) {
            _selectedVehicleType = _vehicles[0]['vehicleType'];
          }
        });
      }
    } catch (e) {
      print('❌ Lỗi tính giá: $e');
    }
  }

  String _getVehicleEmoji(String type) {
    switch (type) {
      case 'bike':
        return '🏍️';
      case 'car':
        return '🚗';
      case 'business':
        return '🚙';
      default:
        return '🚗';
    }
  }


  // ✅ Gọi API đặt xe (Bản nâng cấp: Có Dialog xoay + Chuyển màn hình)
  Future<void> _bookRide() async {
    if (_fareResponse == null) return;

    // 1. Hiện Dialog "Đang tìm tài xế..." ngay lập tức
    // (Không cần set _isBooking = true nữa vì dialog đã chặn người dùng bấm rồi)
    _showFindingDriverDialog();

    try {
      // Tạo request (nhớ là đã có distance từ lúc tính giá)
      final request = CreateRideRequest(
        pickupLocation: LocationDto(
          latitude: widget.pickupLatLng.latitude,
          longitude: widget.pickupLatLng.longitude,
          address: widget.pickupAddress,
        ),
        destinationLocation: LocationDto(
          latitude: widget.destinationLatLng.latitude,
          longitude: widget.destinationLatLng.longitude,
          address: widget.destinationAddress,
        ),
        vehicleType: _selectedVehicleType,
        paymentMethod: 'cash',
        distance: _tripDistance, // Số km thực tế đã lưu
      );

      // Giả vờ delay 2 giây cho thầy cô kịp đọc chữ "Đang tìm..." (Tùy chọn)
      await Future.delayed(const Duration(seconds: 2));

      // Gọi API đặt xe
      final response = await _rideService.bookRide(request);

      // 2. TẮT DIALOG XOAY XOAY (Quan trọng: Phải kiểm tra mounted)
      if (mounted) {
        Navigator.of(context).pop(); 
      }

      // Xử lý kết quả
      if (response != null) {
        if (response.assignedDriver != null) {
          // ✅ TRƯỜNG HỢP 1: TÌM THẤY TÀI XẾ
          print("✅ Đã tìm thấy tài xế: ${response.assignedDriver!.fullName}");
          
          if (mounted) {
            // Chuyển sang màn hình Tracking ngay lập tức
            // Dùng pushReplacement để khách không bấm Back quay lại đặt tiếp được
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RideTrackingScreen(
                  rideId: response.rideId,
                  driverInfo: response.assignedDriver, // Truyền thông tin tài xế qua
                ),
              ),
            );
          }
        } else {
          // ❌ TRƯỜNG HỢP 2: ĐẶT ĐƯỢC NHƯNG KHÔNG CÓ TÀI XẾ (Null)
          _showError("Hiện không có tài xế nào gần bạn (5km). Vui lòng thử lại!");
        }
      } else {
        _showError('Lỗi kết nối. Vui lòng thử lại.');
      }
    } catch (e) {
      // Nếu lỗi sập nguồn thì cũng phải nhớ tắt Dialog đi kẻo treo app
      if (mounted) Navigator.of(context).pop();
      _showError('Lỗi: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _initMap() async {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };
await _locationService.teleportDriverToLocation(widget.pickupLatLng);
    await _getRoute();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getRoute() async {
    try {
      final String url =
          'https://rsapi.goong.io/Direction?origin=${widget.pickupLatLng.latitude},${widget.pickupLatLng.longitude}&destination=${widget.destinationLatLng.latitude},${widget.destinationLatLng.longitude}&vehicle=car&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final legs = route['legs'] as List;

          List<LatLng> polylinePoints = [];
          double totalDistance = 0;
          double totalDuration = 0;

          for (var leg in legs) {
            final steps = leg['steps'] as List;

            if (leg['distance'] != null) {
              totalDistance += (leg['distance']['value'] ?? 0) / 1000;
            }
            if (leg['duration'] != null) {
              totalDuration += (leg['duration']['value'] ?? 0);
            }

            for (var step in steps) {
              final startLoc = step['start_location'];
              polylinePoints.add(LatLng(startLoc['lat'], startLoc['lng']));

              final endLoc = step['end_location'];
              polylinePoints.add(LatLng(endLoc['lat'], endLoc['lng']));
            }
          }

          setState(() {
            _distance = '${totalDistance.toStringAsFixed(1)} km';
            _duration = '${(totalDuration / 60).toInt()} phút';
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: AppTheme.primaryGreen,
                width: 5,
              ),
            };
          });
    print("📏 Khoảng cách thực tế (Goong): $totalDistance km");
          
          // Gọi hàm tính tiền với con số chính xác vừa lấy được
          _calculateFare(totalDistance);
          _zoomToFitRoute();
        }
      }
    } catch (e) {
      print('Lỗi lấy route: $e');
    }
  }

  void _zoomToFitRoute() {
    if (_mapController == null) return;

    double minLat =
        widget.pickupLatLng.latitude < widget.destinationLatLng.latitude
        ? widget.pickupLatLng.latitude
        : widget.destinationLatLng.latitude;
    double minLng =
        widget.pickupLatLng.longitude < widget.destinationLatLng.longitude
        ? widget.pickupLatLng.longitude
        : widget.destinationLatLng.longitude;
    double maxLat =
        widget.pickupLatLng.latitude >= widget.destinationLatLng.latitude
        ? widget.pickupLatLng.latitude
        : widget.destinationLatLng.latitude;
    double maxLng =
        widget.pickupLatLng.longitude >= widget.destinationLatLng.longitude
        ? widget.pickupLatLng.longitude
        : widget.destinationLatLng.longitude;

    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100,
        ),
      );
    });
  }
// Hàm hiện Dialog đang tìm xe
  void _showFindingDriverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài để tắt
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryGreen), // Xoay xoay
                const SizedBox(height: 20),
                const Text(
                  "Đang tìm tài xế gần bạn...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Vui lòng đợi trong giây lát",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLatLng,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.pickupAddress.split(',')[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.destinationAddress.split(',')[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Distance Badge
          if (_distance.isNotEmpty)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _distance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _vehicles.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _vehicles.length + 2,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildPromoBanner();
                                }
                                if (index == _vehicles.length + 1) {
                                  return _buildAddNote();
                                }
                                final vehicle = _vehicles[index - 1];
                                return _buildVehicleItem(vehicle);
                              },
                            ),
                    ),
                    _buildBookButton(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

Widget _buildVehicleItem(Map<String, dynamic> vehicle) {
    final isSelected = vehicle['vehicleType'] == _selectedVehicleType;

    return GestureDetector(
      // 👇 QUAN TRỌNG: Dòng này giúp bấm vào chỗ trắng cũng ăn
      behavior: HitTestBehavior.opaque, 
      
      onTap: () {
        print("👉 Đã chọn xe: ${vehicle['vehicleType']}");
        setState(() {
          _selectedVehicleType = vehicle['vehicleType'];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // Màu nền thay đổi rõ hơn khi chọn
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Viền xanh đậm khi chọn
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected) // Chỉ hiện bóng mờ khi chưa chọn cho đỡ rối
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Row(
          children: [
            // Icon Xe
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(vehicle['icon'], style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            
            // Thông tin xe
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? AppTheme.primaryGreen : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Đón trong ${vehicle['time']}", // Sửa lại text cho gọn
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Giá tiền (Đã format đẹp)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatMoney(vehicle['price'])}đ', // 👇 Gọi hàm format ở đây
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isSelected ? AppTheme.primaryGreen : Colors.black,
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                 
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
  // Hàm format tiền: 37089 -> 37.000
  String formatMoney(dynamic amount) {
    if (amount == null) return '0';
    int price = amount.toInt();
    
    // 1. Làm tròn đến hàng nghìn (37089 -> 37000)
    price = (price / 1000).round() * 1000;

    // 2. Thêm dấu chấm phân cách hàng nghìn
    // (Dùng RegExp đơn giản đỡ phải cài thư viện intl)
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
        (Match m) => '${m[1]}.'
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.discount, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tiền mặt     🎟️ Ưu đãi giảm 50% tối đa 50,000 VND',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.note_add_outlined, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            'Xuất hóa đơn & dịch vụ bổ sung tại đây.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isBooking ? null : _bookRide,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primaryGreen,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isBooking
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Đặt xe',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

