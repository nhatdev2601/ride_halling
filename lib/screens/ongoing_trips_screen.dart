// ✅ OngoingTripsScreen (lib/screens/ongoing_trips_screen.dart)
// Màn hình chuyến đi đang diễn ra: List chuyến, nút điều hướng & kết thúc

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/trip_service.dart';
import '../models/ride_models.dart';

class OngoingTripsScreen extends StatefulWidget {
  const OngoingTripsScreen({super.key});

  @override
  State<OngoingTripsScreen> createState() => _OngoingTripsScreenState();
}

class _OngoingTripsScreenState extends State<OngoingTripsScreen> {
  final TripService _tripService = TripService();
  List<Ride> _ongoingTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOngoingTrips();
  }

  // ✅ Load chuyến đang diễn ra
  Future<void> _loadOngoingTrips() async {
    setState(() => _isLoading = true);
    try {
      _ongoingTrips = await _tripService.getOngoingTrips();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải chuyến: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Kết thúc chuyến
  Future<void> _endTrip(Ride trip) async {
    final success = await _tripService.endTrip(trip.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kết thúc chuyến thành công!')),
      );
      _loadOngoingTrips(); // Reload
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi kết thúc chuyến')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        title: const Text(
          'Chuyến đi',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _loadOngoingTrips,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _ongoingTrips.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 80, color: AppTheme.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có chuyến nào',
                    style: TextStyle(fontSize: 18, color: AppTheme.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ongoingTrips.length,
              itemBuilder: (context, index) {
                final trip = _ongoingTrips[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: const Icon(
                        Icons.navigation,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    title: Text('Chuyến #${trip.id.substring(0, 8)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Khách: ${trip.passengerName}'),
                        Text('Trạng thái: ${trip.status}'),
                        Text('Thu nhập: ${trip.earnings.toStringAsFixed(0)}đ'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.map,
                            color: AppTheme.primaryGreen,
                          ),
                          onPressed: () {
                            // ✅ Mở Google Maps điều hướng (sử dụng url_launcher)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Mở bản đồ đến ${trip.dropoffAddress}',
                                ),
                              ),
                            );
                          },
                          tooltip: 'Điều hướng',
                        ),
                        if (trip.status ==
                            'ongoing') // Chỉ show nếu đang diễn ra
                          IconButton(
                            icon: const Icon(Icons.stop, color: AppTheme.error),
                            onPressed: () => _showEndTripDialog(trip),
                            tooltip: 'Kết thúc',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ✅ Dialog xác nhận kết thúc chuyến
  void _showEndTripDialog(Ride trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc chuyến'),
        content: Text('Xác nhận kết thúc chuyến với ${trip.passengerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endTrip(trip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
