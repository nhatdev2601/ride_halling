// ✅ TripDetailScreen (lib/screens/trip_detail_screen.dart)
// Màn hình chi tiết chuyến: Bản đồ tuyến đường in-app (Goong Directions), thông tin chuyến, nút hành động
// ✅ Cập nhật: Không mở external Google Maps, dùng Goong API để vẽ route in-app
// ✅ Sử dụng _getCurrentLocation & Goong API tương tự LocationSearchScreen để update vị trí real-time nếu cần
// ✅ Giả sử Ride có dropoffLat/Lng (cập nhật model nếu chưa)

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../services/trip_service.dart';
import '../models/ride_models.dart'; // Ride model
import 'package:geolocator/geolocator.dart'; // Từ LocationSearchScreen
import 'package:http/http.dart' as http;
import 'dart:convert';

class TripDetailScreen extends StatefulWidget {
  final Ride ride;
  const TripDetailScreen({super.key, required this.ride});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TripService _tripService = TripService();
  GoogleMapController? _mapController;
  bool _isLoading = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng?
  _currentDriverPosition; // ✅ Vị trí tài xế hiện tại (từ _getCurrentLocation)
  static const String goongApiKey =
      'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ'; // ✅ lowerCamelCase

  late Ride _ride; // ✅ Local non-final để update

  @override
  void initState() {
    super.initState();
    _ride = widget.ride; // ✅ Init local
    _loadTripDetails();
    _getCurrentLocation(); // ✅ Tích hợp _getCurrentLocation từ LocationSearchScreen
  }

  // ✅ Tích hợp _getCurrentLocation từ LocationSearchScreen (adapt cho driver)
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Vui lòng bật GPS để lấy vị trí.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Ứng dụng bị từ chối quyền truy cập vị trí.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentDriverPosition = LatLng(
            position.latitude,
            position.longitude,
          );
        });
      }

      // ✅ Update marker vị trí tài xế trên map nếu có
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentDriverPosition!, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      _showError('Lỗi lấy vị trí: ${e.toString()}');
    }
  }

  // ✅ Hiển thị lỗi (từ LocationSearchScreen)
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ Load chi tiết chuyến: Setup markers, polyline từ Goong Directions, fit camera
  Future<void> _loadTripDetails() async {
    setState(() => _isLoading = true);
    try {
      // Reload ride nếu cần...

      // ✅ Setup markers cho pickup, dropoff, & current driver position
      final pickupPos = LatLng(
        _ride.pickupLat ?? 10.7769,
        _ride.pickupLng ?? 106.7009,
      );
      final dropoffPos = LatLng(
        _ride.dropoffLat ?? 10.7769, // Từ model
        _ride.dropoffLng ?? 106.7009,
      );

      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPos,
          infoWindow: InfoWindow(
            title: 'Điểm đón',
            snippet: _ride.pickupAddress ?? 'Chưa xác định',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffPos,
          infoWindow: InfoWindow(
            title: 'Điểm đến',
            snippet: _ride.dropoffAddress ?? 'Chưa xác định',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
        if (_currentDriverPosition != null)
          Marker(
            markerId: const MarkerId('driver_current'),
            position: _currentDriverPosition!,
            infoWindow: const InfoWindow(title: 'Vị trí tài xế'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
      };

      // ✅ Vẽ tuyến đường polyline từ Goong Directions (sử dụng pickup -> dropoff)
      await _fetchAndDrawRoute(pickupPos, dropoffPos);

      // ✅ Fit camera bounds cả pickup, dropoff, & current position
      if (_mapController != null) {
        final allPoints = [pickupPos, dropoffPos];
        if (_currentDriverPosition != null)
          allPoints.add(_currentDriverPosition!);
        final bounds = _calculateBounds(allPoints);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi tải chi tiết: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Tính bounds cho multiple points
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  // ✅ Fetch route từ Goong Directions API và vẽ polyline (tích hợp _getPlaceSuggestions style)
  Future<void> _fetchAndDrawRoute(LatLng origin, LatLng destination) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://rsapi.goong.io/Direction'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'origin': '${origin.latitude},${origin.longitude}',
              'destination': '${destination.latitude},${destination.longitude}',
              'mode': 'driving',
              'api_key': goongApiKey, // ✅ Sử dụng constant
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['routes'] != null && json['routes'].isNotEmpty) {
          final route = json['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          if (polylinePoints != null) {
            final points = _decodePolyline(polylinePoints);
            if (mounted) {
              setState(() {
                _polylines = {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: points,
                    color: AppTheme.primaryGreen,
                    width: 5,
                  ),
                };
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetch route: $e'); // ✅ Thay print bằng debugPrint
    }
  }

  // ✅ Decode polyline (từ Goong, tương tự Google)
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // ✅ Các method khác giữ nguyên (_acceptTrip, _startTrip, _endTrip)
  Future<void> _acceptTrip() async {
    if (_ride.status != 'requested') return;

    setState(() => _isLoading = true);
    try {
      final accepted = await _tripService.acceptTrip(_ride.id);
      if (accepted != null) {
        if (mounted) {
          setState(() => _ride = accepted); // ✅ Update local _ride
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Chuyến đã nhận!')));
        }
      } else {
        throw Exception('Không thể nhận chuyến');
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi nhận chuyến: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startTrip() async {
    if (_ride.status != 'accepted') return;

    if (mounted) {
      setState(() {
        _ride.status = 'ongoing'; // ✅ Update local status (non-final)
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chuyến đã bắt đầu!')));
    }
  }

  Future<void> _endTrip() async {
    if (_ride.status != 'ongoing') return;

    final success = await _tripService.endTrip(_ride.id);
    if (success && mounted) {
      setState(() {
        _ride.status =
            'completed'; // ✅ Update local status (lowercase, non-final)
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chuyến đã kết thúc! Thu nhập: ${_ride.earnings.toStringAsFixed(0)}đ',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else if (mounted) {
      _showError('Lỗi kết thúc chuyến');
    }
  }

  // ✅ Navigation: Thay vì external, zoom to route & update current position
  Future<void> _launchNavigation() async {
    if (_mapController != null) {
      await _getCurrentLocation(); // Update vị trí hiện tại
      final pickupPos = LatLng(_ride.pickupLat ?? 0, _ride.pickupLng ?? 0);
      final dropoffPos = LatLng(_ride.dropoffLat ?? 0, _ride.dropoffLng ?? 0);
      final bounds = _calculateBounds([
        pickupPos,
        dropoffPos,
        _currentDriverPosition ?? pickupPos,
      ]);
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang điều hướng trên bản đồ')),
        );
      }
    } else if (mounted) {
      _showError('Không thể điều hướng');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text('Chuyến ${_ride.status}'), // ✅ Sử dụng local _ride
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _loadTripDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ Bản đồ in-app với route (tăng height)
                  SizedBox(
                    height: 350,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                            _ride.pickupLat != null && _ride.pickupLng != null
                            ? LatLng(_ride.pickupLat!, _ride.pickupLng!)
                            : const LatLng(10.7769, 106.7009),
                        zoom: 14.0,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _markers,
                      polylines: _polylines, // ✅ Route in-app
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Thông tin chuyến (sử dụng _ride)
                  Container(
                    color: AppTheme.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chi tiết chuyến',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(_ride.status.toUpperCase()),
                              backgroundColor: _getStatusColor(_ride.status),
                            ),
                          ],
                        ),
                        const Divider(),
                        _buildDetailRow(
                          Icons.person,
                          'Khách hàng',
                          _ride.passengerName,
                        ),
                        _buildDetailRow(
                          Icons.location_on,
                          'Điểm đón',
                          _ride.pickupAddress ?? 'Chưa xác định',
                        ),
                        _buildDetailRow(
                          Icons.flag,
                          'Điểm đến',
                          _ride.dropoffAddress ?? 'Chưa xác định',
                        ),
                        _buildDetailRow(
                          Icons.straighten,
                          'Khoảng cách',
                          '${_ride.distance.toStringAsFixed(1)} km',
                        ),
                        _buildDetailRow(
                          Icons.attach_money,
                          'Thu nhập',
                          '${_ride.earnings.toStringAsFixed(0)}đ',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ Nút hành động: Navigation in-app
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_ride.status == 'requested')
                          ElevatedButton.icon(
                            onPressed: _acceptTrip,
                            icon: const Icon(
                              Icons.check,
                              color: AppTheme.white,
                            ),
                            label: const Text('Nhận chuyến'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: AppTheme.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        if (_ride.status == 'accepted')
                          ElevatedButton.icon(
                            onPressed: _startTrip,
                            icon: const Icon(
                              Icons.play_arrow,
                              color: AppTheme.white,
                            ),
                            label: const Text('Bắt đầu chuyến'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: AppTheme.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        if (_ride.status == 'ongoing')
                          Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed:
                                    _launchNavigation, // ✅ In-app navigation
                                icon: const Icon(
                                  Icons.navigation,
                                  color: AppTheme.white,
                                ),
                                label: const Text('Điều hướng trên bản đồ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: AppTheme.white,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _endTrip,
                                icon: const Icon(
                                  Icons.stop,
                                  color: AppTheme.white,
                                ),
                                label: const Text('Kết thúc chuyến'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: AppTheme.white,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                            ],
                          ),
                        if (_ride.status == 'completed')
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(
                                0.1,
                              ), // ✅ Fixed: withOpacity instead of withValues
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Chuyến đã hoàn thành! Thu nhập: ${_ride.earnings.toStringAsFixed(0)}đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ Helper: Row chi tiết (giữ nguyên)
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Màu cho status chip (giữ nguyên)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'accepted':
        return AppTheme.primaryGreen;
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return AppTheme.grey;
    }
  }
}
