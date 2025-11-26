import 'dart:async'; // Để dùng Timer
import 'package:flutter/material.dart';
import '../models/ride_models.dart';
import '../services/ride_service.dart';
import '../theme/app_theme.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final DriverInfo? driverInfo; // Thông tin tài xế ban đầu

  const RideTrackingScreen({super.key, required this.rideId, this.driverInfo});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final RideService _rideService = RideService();

  Timer? _timer;
  String _currentStatus = "accepted"; // Trạng thái mặc định
  String _statusText = "Tài xế đang đến...";
  bool _isDisposed = false; // Cờ để tránh lỗi khi thoát màn hình
  bool _isCancelling = false;
  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel(); // 🛑 Quan trọng: Hủy timer khi thoát
    super.dispose();
  }

  // 🔄 Hàm định kỳ hỏi Server
  void _startPolling() {
    // Cứ 3 giây gọi 1 lần
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkRideStatus();
    });
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
              Navigator.pop(ctx); // Đóng dialog trước
              // Gọi hàm xử lý hủy
              _handleCancelRide(
                reasonController.text.isEmpty
                    ? "Khách hàng đổi ý"
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

  // 👇 2. Hàm gọi Service
  Future<void> _handleCancelRide(String reason) async {
    setState(() {
      _isCancelling = true; // Bật loading
    });

    // Gọi Service
    final success = await _rideService.cancelRide(widget.rideId, reason);

    if (_isDisposed) return;

    setState(() {
      _isCancelling = false; // Tắt loading
    });

    if (success) {
      // Dừng timer polling
      _timer?.cancel();

      // Cập nhật UI ngay lập tức
      setState(() {
        _currentStatus = 'cancelled';
        _updateStatusText();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã hủy chuyến thành công!")),
      );

      // Tùy chọn: Quay về màn hình chính sau 1s
     Future.delayed(const Duration(milliseconds: 500), () {
       if (mounted) {
         // pop() nghĩa là đóng màn hình hiện tại, nó sẽ lộ ra màn hình cũ bên dưới
         Navigator.of(context).pop(); 
       }
    });
    } else {
  _timer?.cancel(); // Dừng polling ngay lập tức

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lỗi: Không tìm thấy chuyến xe (hoặc đã hoàn thành). Đang thoát..."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      // Đợi 2 giây rồi đá về trang chủ
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDisposed) {
           Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
    
  }

  Future<void> _checkRideStatus() async {
    try {
      // Gọi API lấy thông tin chuyến đi mới nhất
      // Mày cần đảm bảo RideService có hàm getRide(rideId) nhé
      final rideDetail = await _rideService.getRide(widget.rideId);

      if (_isDisposed || rideDetail == null) return;

      if (rideDetail.status != _currentStatus) {
        setState(() {
          _currentStatus = rideDetail.status;
          _updateStatusText();
        });

        // Nếu hoàn thành thì dừng timer và hiện thông báo
        if (_currentStatus == 'completed') {
          _timer?.cancel();
          _showPaymentDialog(rideDetail.totalFare);
        }
      }
    } catch (e) {
      print("Lỗi polling: $e");
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
        _statusText = "Đang di chuyển đến nơi...";
        break;
      case 'completed':
        _statusText = "Đã đến nơi!";
        break;
      case 'cancelled':
        _statusText = "Chuyến xe đã bị hủy";
        _timer?.cancel();
        break;
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
          "Vui lòng thanh toán: ${totalFare.toStringAsFixed(0)}đ",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              Navigator.of(
                context,
              ).popUntil((route) => route.isFirst); // Về trang chủ
            },
            child: const Text("Đóng", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy info tài xế (ưu tiên từ widget truyền qua)
    final driverName = widget.driverInfo?.fullName ?? "Tài xế";
    final plate = widget.driverInfo?.vehicle?.licensePlate ?? "";
    final vehicle = widget.driverInfo?.vehicle?.model ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Theo dõi chuyến đi"),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading:
            false, // Ẩn nút back để không thoát lung tung
      ),
      body: Stack(
        children: [
          // 1. MAP PLACEHOLDER (Để sau này mày gắn Google Map vào đây)
          Container(
            color: Colors.grey[100],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.black12),
                  SizedBox(height: 10),
                  Text(
                    "Bản đồ realtime đang cập nhật...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // 2. THÔNG TIN TRẠNG THÁI & TÀI XẾ
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
                  // Trạng thái
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

                  // Tài xế Info
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
                      // Nút gọi
                      FloatingActionButton.small(
                        onPressed: () {},
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.phone, color: Colors.white),
                        elevation: 0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  // Nút Huỷ (Chỉ hiện khi chưa hoàn thành)
                  if (_currentStatus != 'completed' &&
                      _currentStatus !=
                          'cancelled' && // Thêm check này để ẩn nút nếu đã hủy rồi
                      _currentStatus !=
                          'in_progress') // Thường thì đang đi không cho hủy, tùy mày
                    Center(
                      child: _isCancelling
                          ? const CircularProgressIndicator() // Hiện loading nếu đang gọi API
                          : TextButton.icon(
                              onPressed:
                                  _showCancelConfirmation, // 👈 Gắn hàm vào đây
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.orange;
      case 'arrived':
        return Colors.blue;
      case 'in_progress':
        return AppTheme.primaryGreen; // Màu xanh lá
      case 'completed':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
