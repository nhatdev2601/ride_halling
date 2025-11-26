// ✅ HomeScreenDriver (lib/screens/home_screen_driver.dart)
// Màn hình trang chủ cho tài xế: Bản đồ + List chuyến gần (tích hợp LocationService & TripService)

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../services/trip_service.dart';
import '../services/location_service.dart'; // LocationService có sẵn
import '../models/ride_models.dart'; // Ride model
import 'trip_detail_screen.dart'; // Screen chi tiết chuyến (tạo sau)

class HomeScreenDriver extends StatefulWidget {
  const HomeScreenDriver({super.key});

  @override
  State<HomeScreenDriver> createState() => _HomeScreenDriverState();
}

class _HomeScreenDriverState extends State<HomeScreenDriver> {
  final TripService _tripService = TripService();
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  List<Ride> _nearbyTrips = [];
  bool _isLoading = true;
  String _currentAddress = 'Đang tải vị trí...';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationAndTrips();
  }

  // ✅ Load vị trí hiện tại và chuyến gần
  Future<void> _loadCurrentLocationAndTrips() async {
    setState(() => _isLoading = true);
    try {
      final locationResult = await _locationService.getCurrentLocation();
      if (locationResult.success && locationResult.location != null) {
        setState(() {
          _currentLocation = locationResult.location!;
          _currentAddress = locationResult.address ?? 'Vị trí hiện tại';
        });

        // Di chuyển camera map đến vị trí
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
          );
        }

        // Load chuyến gần
        _nearbyTrips = await _tripService.getNearbyTrips(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );
      } else {
        _showLocationError(locationResult.errorMessage ?? 'Lỗi không xác định');
      }
    } catch (e) {
      _showError('Lỗi tải dữ liệu: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Hiển thị lỗi vị trí
  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: AppTheme.white,
          onPressed: _loadCurrentLocationAndTrips,
        ),
      ),
    );
  }

  // ✅ Hiển thị lỗi chung
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        title: Text(
          'Trang chủ',
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _loadCurrentLocationAndTrips,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : Column(
              children: [
                // ✅ Phần bản đồ (Google Maps)
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target:
                              _currentLocation ??
                              const LatLng(10.7769, 106.7009), // Default TP.HCM
                          zoom: 15.0,
                        ),
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: {
                          // Marker vị trí hiện tại
                          Marker(
                            markerId: const MarkerId('current_location'),
                            position:
                                _currentLocation ??
                                const LatLng(10.7769, 106.7009),
                            infoWindow: InfoWindow(title: _currentAddress),
                          ),
                          // Markers cho chuyến gần (tùy chọn)
                          ..._nearbyTrips.asMap().entries.map((entry) {
                            final ride = entry.value;
                            return Marker(
                              markerId: MarkerId(ride.id),
                              position: LatLng(
                                ride.pickupLat ?? 0,
                                ride.pickupLng ?? 0,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                              infoWindow: InfoWindow(
                                title: ride.passengerName,
                                snippet:
                                    '${ride.distance}km - ${ride.earnings.toStringAsFixed(0)}đ',
                              ),
                            );
                          }).toSet(),
                        },
                      ),
                      // Nút refresh vị trí
                      Positioned(
                        top: 10,
                        right: 10,
                        child: FloatingActionButton(
                          mini: true,
                          heroTag: 'refresh_location',
                          backgroundColor: AppTheme.primaryGreen,
                          onPressed: _loadCurrentLocationAndTrips,
                          child: const Icon(
                            Icons.my_location,
                            color: AppTheme.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ Danh sách chuyến gần
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyến gần bạn ($_nearbyTrips.length chuyến)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _nearbyTrips.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: AppTheme.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Không có chuyến nào gần đây',
                                        style: TextStyle(color: AppTheme.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _nearbyTrips.length,
                                  itemBuilder: (context, index) {
                                    final trip = _nearbyTrips[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.primaryGreen
                                              .withOpacity(0.1),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                        title: Text(trip.passengerName),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Từ: ${trip.pickupAddress ?? 'Địa điểm A'}',
                                            ),
                                            Text(
                                              'Đến: ${trip.dropoffAddress ?? 'Địa điểm B'}',
                                            ),
                                            Text(
                                              'Khoảng cách: ${trip.distance.toStringAsFixed(1)}km',
                                            ),
                                            Text(
                                              'Thu nhập: ${trip.earnings.toStringAsFixed(0)}đ',
                                            ),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed: () async {
                                            final accepted = await _tripService
                                                .acceptTrip(trip.id);
                                            if (accepted != null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Chuyến đã nhận!',
                                                  ),
                                                ),
                                              );
                                              _loadCurrentLocationAndTrips(); // Reload
                                            } else {
                                              _showError(
                                                'Không thể nhận chuyến',
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryGreen,
                                            foregroundColor: AppTheme.white,
                                          ),
                                          child: const Text('Nhận'),
                                        ),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TripDetailScreen(ride: trip),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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

// ✅ Placeholder TripDetailScreen
class TripDetailScreen extends StatelessWidget {
  final Ride ride;
  const TripDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết chuyến ${ride.id}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Khách: ${ride.passengerName}'),
            Text('Từ: ${ride.pickupAddress ?? ''}'),
            Text('Đến: ${ride.dropoffAddress ?? ''}'),
            Text('Thu nhập: ${ride.earnings.toStringAsFixed(0)}đ'),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}
