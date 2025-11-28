import 'dart:async';
import 'dart:convert'; // 📦 Để decode JSON
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http; // 📦 Gọi API
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ride_hailing/screens/main_screen.dart'; //  Đổi sang MainScreen
import '../models/ride_models.dart';
import '../services/ride_service.dart';
import '../services/location_service_driver.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart'; // 📦 Thêm dòng này lên đầu

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final DriverInfo? driverInfo;

  const RideTrackingScreen({super.key, required this.rideId, this.driverInfo});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  // Services
  final RideService _rideService = RideService();
  final LocationServiceDriver _simulationService = LocationServiceDriver();

  // Map Variables
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // 🆕 Biến lưu đường vẽ

  // Vị trí
  LatLng _driverLocation = const LatLng(10.762622, 106.660172);
  LatLng? _pickupLocation;
  bool _isFirstLoad = true;

  // Logic Variables
  Timer? _timer;
  StreamSubscription? _firebaseSubscription;
  DatabaseReference? _rideRef;

  String _currentStatus = "accepted";
  String _statusText = "Tài xế đang đến...";
  bool _isDisposed = false;
  bool _isCancelling = false;
  BitmapDescriptor? _driverIcon;
  DriverInfo? _currentDriverInfo;
  //  Key Goong của mày (Lấy từ code mày gửi)
  static const String GOONG_API_KEY =
      'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ';

  @override
  void initState() {
    super.initState();
    _currentDriverInfo = widget.driverInfo;
    _loadCustomMarker();
    _fetchRideDetails();

    _startPollingStatus();
    _startFirebaseListener();

    Future.delayed(const Duration(milliseconds: 500), () {
      _triggerDriverSimulation();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _firebaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchRideDetails() async {
    final ride = await _rideService.getRideForTracking(widget.rideId);
    if (ride != null) {
      if (mounted) {
        setState(() {
          _pickupLocation = LatLng(
            ride.pickupLocationLat,
            ride.pickupLocationLng,
          );

          //  CẬP NHẬT THÔNG TIN TÀI XẾ (Nếu API trả về có dữ liệu)
          if (ride.driverInfo != null) {
            _currentDriverInfo = ride.driverInfo;
            print(" SĐT Tài xế từ API: ${_currentDriverInfo?.phoneNumber}");
          }

          _markers.add(
            Marker(
              markerId: const MarkerId('pickup'),
              position: _pickupLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(title: "Điểm đón"),
            ),
          );
        });
        _getRouteFromGoong();
      }
    }
  }

  // ---------------------------------------------------------
  // 🛣️ LOGIC VẼ ĐƯỜNG BẰNG GOONG API (Thay cho Google)
  // ---------------------------------------------------------
  Future<void> _getRouteFromGoong() async {
    if (_pickupLocation == null) return;

    try {
      // Gọi API Goong: Từ Tài xế -> Điểm đón
      final String url =
          'https://rsapi.goong.io/Direction?origin=${_driverLocation.latitude},${_driverLocation.longitude}&destination=${_pickupLocation!.latitude},${_pickupLocation!.longitude}&vehicle=car&api_key=$GOONG_API_KEY';

      print("🌐 Calling Goong API: $url");

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final legs = route['legs'] as List;

          List<LatLng> polylinePoints = [];

          // Parse các step để lấy tọa độ vẽ đường
          for (var leg in legs) {
            final steps = leg['steps'] as List;
            for (var step in steps) {
              final startLoc = step['start_location'];
              polylinePoints.add(LatLng(startLoc['lat'], startLoc['lng']));

              final endLoc = step['end_location'];
              polylinePoints.add(LatLng(endLoc['lat'], endLoc['lng']));
            }
          }

          if (mounted) {
            setState(() {
              _polylines = {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: polylinePoints,
                  color: AppTheme.primaryGreen, // Màu xanh giống App mày
                  width: 5,
                ),
              };
            });
          }
        }
      } else {
        print(" Lỗi Goong API: ${response.statusCode}");
      }
    } catch (e) {
      print(' Exception Goong: $e');
    }
  }

  Future<void> _triggerDriverSimulation() async {
    if (_currentStatus == 'accepted') {
      print("🚀 [Tracking] Kích hoạt tài xế di chuyển...");
      await _simulationService.teleportDriverToPickup(widget.rideId);
    }
  }

  void _startFirebaseListener() {
    //  Link Firebase Singapore chuẩn của mày
    const String databaseUrl =
        'https://appride-f2bb5-default-rtdb.asia-southeast1.firebasedatabase.app';

    _rideRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    ).ref('rides/${widget.rideId}');

    _firebaseSubscription = _rideRef!.onValue.listen((event) {
      if (_isDisposed) return;
      final rawData = event.snapshot.value;

      if (rawData != null && rawData is Map) {
        final data = Map<dynamic, dynamic>.from(rawData);
        if (data['driver_location'] != null) {
          final loc = Map<dynamic, dynamic>.from(data['driver_location']);
          double lat = double.parse(loc['lat'].toString());
          double lng = double.parse(loc['lng'].toString());
          double rotation = loc['bearing'] != null
              ? double.parse(loc['bearing'].toString())
              : 0.0;

          _updateDriverMarker(LatLng(lat, lng), rotation);
        }
      }
    });
  }

  Future<void> _updateDriverMarker(LatLng newPos, double rotation) async {
    if (_isDisposed) return;

    setState(() {
      _driverLocation = newPos;
      // Cập nhật marker tài xế
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: newPos,
          rotation: rotation,
          icon:
              _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: widget.driverInfo?.fullName ?? "Tài xế",
            snippet: widget.driverInfo?.vehicle?.licensePlate,
          ),
        ),
      );
    });

    //  VẼ LẠI ĐƯỜNG KHI TÀI XẾ DI CHUYỂN (Để đường ngắn dần lại)
    _getRouteFromGoong();

    final GoogleMapController controller = await _mapController.future;
    if (_isFirstLoad) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 16, bearing: rotation),
        ),
      );
      _isFirstLoad = false;
    } else {
      controller.animateCamera(CameraUpdate.newLatLng(newPos));
    }
  }

  // ... (Các hàm _startPollingStatus, _checkRideStatus, _showCancelConfirmation... giữ nguyên)
  void _startPollingStatus() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkRideStatus();
    });
  }

  Future<void> _checkRideStatus() async {
    try {
      final rideDetail = await _rideService.getRideForTracking(widget.rideId);
      if (_isDisposed || rideDetail == null) return;

      if (rideDetail.status != _currentStatus) {
        setState(() {
          _currentStatus = rideDetail.status;
          _updateStatusText();
        });

        if (_currentStatus == 'completed') {
          _timer?.cancel();
          _firebaseSubscription?.cancel();
          _showPaymentDialog(rideDetail.totalFare);
        }
      }
    } catch (e) {
      print("Lỗi polling status: $e");
    }
  }

  void _updateStatusText() {
    switch (_currentStatus) {
      case 'accepted':
        _statusText = "Tài xế đang đến...";
        break;
      case 'arrived':
        _statusText = "Tài xế đã đến điểm đón!";
        break;
      case 'in_progress':
        _statusText = "Đang di chuyển...";
        break;
      case 'completed':
        _statusText = "Đã đến nơi!";
        break;
      case 'cancelled':
        _statusText = "Chuyến xe đã hủy";
        break;
    }
  }

  Future<void> _callDriver(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không tìm thấy số điện thoại tài xế")),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(' ', ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print(" Không thể mở trình gọi điện");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thiết bị không hỗ trợ gọi điện")),
        );
      }
    } catch (e) {
      print(" Lỗi gọi điện: $e");
    }
  }

  void _loadCustomMarker() async {
    try {
      final icon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(100, 100)),
        'assets/images/car_icon.png',
      );
      setState(() {
        _driverIcon = icon;
      });
    } catch (e) {
      print(" Lỗi load icon xe: $e");
    }
  }

  void _showCancelConfirmation() {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bạn có chắc muốn hủy chuyến đi này không?"),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Nhập lý do (tùy chọn)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Không", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleCancelRide(
                reasonController.text.isEmpty
                    ? "Khách hủy"
                    : reasonController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Hủy chuyến",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelRide(String reason) async {
    setState(() => _isCancelling = true);
    final success = await _rideService.cancelRide(widget.rideId, reason);

    if (_isDisposed) return;
    setState(() => _isCancelling = false);

    if (success) {
      _timer?.cancel();
      _firebaseSubscription?.cancel();
      setState(() {
        _currentStatus = 'cancelled';
        _updateStatusText();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã hủy chuyến!")));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          //  Quay về MainScreen và xóa toàn bộ stack để không bị lạc vào màn hình cũ
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi hủy chuyến hoặc chuyến đã hoàn thành!"),
        ),
      );
    }
  }

  void _showPaymentDialog(double totalFare) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text("Chuyến đi hoàn tất"),
          ],
        ),
        content: Text(
          "Vui lòng thanh toán: ${formatMoney(totalFare)}đ",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      const MainScreen(), //  Quay về MainScreen (có bottom nav)
                ),
                (route) => false, // Xóa hết stack cũ
              );
            },
            child: const Text("Đóng", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String formatMoney(dynamic amount) {
    if (amount == null) return '0';
    int price = amount.toInt();
    price = (price / 1000).round() * 1000;
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.orange;
      case 'arrived':
        return Colors.blue;
      case 'in_progress':
        return AppTheme.primaryGreen;
      case 'completed':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driverInfo?.fullName ?? "Tài xế";
    final plate = widget.driverInfo?.vehicle?.licensePlate ?? "";
    final vehicle = widget.driverInfo?.vehicle?.model ?? "";

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _driverLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines, // 🆕 Đã thêm đường vẽ
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
          ),

          // Nút Back
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Panel Thông tin
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(_currentStatus),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$vehicle • $plate",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FloatingActionButton.small(
                        onPressed: () {
                          // Lấy số điện thoại từ biến _currentDriverInfo
                          final phone = _currentDriverInfo?.phoneNumber;
                          print(" Đang gọi số: $phone");
                          if (phone != null) {
                            _callDriver(phone);
                          }
                        },
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.phone, color: Colors.white),
                        elevation: 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  if (_currentStatus != 'completed' &&
                      _currentStatus != 'cancelled' &&
                      _currentStatus != 'in_progress')
                    Center(
                      child: _isCancelling
                          ? const CircularProgressIndicator()
                          : TextButton.icon(
                              onPressed: _showCancelConfirmation,
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text(
                                "Huỷ chuyến đi",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
