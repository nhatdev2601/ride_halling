import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/ride_service.dart';
import '../models/ride_models.dart'; // Model RideHistoryItem

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final RideService _rideService = RideService();
  late Future<List<RideHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _rideService.getRideHistory();
    });
  }

  // --- HELPERS ---
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal(); 
    final diff = now.difference(localDate);

    if (diff.inDays == 0 && localDate.day == now.day) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(localDate)}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && localDate.day != now.day)) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(localDate)}';
    } else {
      return DateFormat('dd/MM/yyyy • HH:mm').format(localDate);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return AppTheme.success;
      case 'cancelled': return AppTheme.error;
      case 'in_progress': return Colors.blue;
      case 'accepted': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      case 'in_progress': return 'Đang đi';
      case 'accepted': return 'Tài xế nhận';
      case 'requesting': return 'Đang tìm xe';
      default: return status;
    }
  }

  IconData _getVehicleIcon(String type) {
    if (type.toLowerCase() == 'bike') return Icons.motorcycle;
    if (type.toLowerCase().contains('car')) return Icons.directions_car;
    return Icons.local_taxi;
  }

  String _getVehicleName(String type) {
    if (type == 'bike') return "RideBike";
    if (type == 'car') return "RideCar 4 chỗ";
    if (type == 'business') return "RideCar 7 chỗ";
    return type;
  }

  String _getPaymentMethodText(String? method) {
    if (method == 'cash') return 'Tiền mặt';
    if (method == 'wallet') return 'Ví điện tử';
    return 'Tiền mặt'; // Mặc định
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lịch sử chuyến đi',
          style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      
      // 👇 DÙNG FUTURE BUILDER ĐỂ LOAD API
      body: FutureBuilder<List<RideHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }
          
          // 2. Có lỗi
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
          }

          final rides = snapshot.data ?? [];

          // 3. Danh sách trống
          if (rides.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Bạn chưa có chuyến đi nào", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. Hiển thị danh sách
          return RefreshIndicator(
            onRefresh: () async => _loadHistory(),
            color: AppTheme.primaryGreen,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final trip = rides[index];
                return _buildHistoryItem(trip);
              },
            ),
          );
        },
      ),
    );
  }

  // Widget Item (Card)
  Widget _buildHistoryItem(RideHistoryItem trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // _showTripDetails(trip); // Tạm thời comment vì chưa có API lấy chi tiết full
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Ngày & Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(trip.createdAt),
                      style: const TextStyle(fontSize: 14, color: AppTheme.grey, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trip.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(trip.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(trip.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Body: Xe & Địa chỉ
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getVehicleIcon(trip.vehicleType), color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pickup
                          Row(children: [
                            const Icon(Icons.circle, color: AppTheme.primaryGreen, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(trip.pickupAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 8),
                          // Dropoff
                          Row(children: [
                            const Icon(Icons.square, color: AppTheme.error, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(trip.dropoffAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer: Tên xe, Payment, Giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getVehicleName(trip.vehicleType),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPaymentMethodText(trip.paymentMethod),
                          style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(trip.totalFare),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.black),
                        ),
                        if (trip.status == 'completed') ...[
                           const SizedBox(height: 4),
                           // Fake rating tạm thời vì API list chưa trả về rating
                           const Row(children: [
                             Icon(Icons.star, color: AppTheme.warning, size: 14),
                             SizedBox(width: 2),
                             Text('5.0', style: TextStyle(fontSize: 12, color: AppTheme.grey)),
                           ])
                        ]
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}