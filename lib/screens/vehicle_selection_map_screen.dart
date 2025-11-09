import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

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

  static const String GOONG_API_KEY =
      'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ';

  final List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Xanh Car',
      'icon': '🚗',
      'seats': 4,
      'time': '5 phút',
      'price': 17000,
      'oldPrice': 34000,
      'promo': 'Tiện lợi, giá hời',
    },
    {
      'name': 'Business',
      'icon': '🚙',
      'seats': 4,
      'time': '5 phút',
      'price': 60000,
      'oldPrice': null,
      'promo': null,
    },
    {
      'name': 'Xanh Bike',
      'icon': '🏍️',
      'seats': 1,
      'time': '5 phút',
      'price': 22000,
      'oldPrice': null,
      'promo': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initMap();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
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
                      Column(
                        children: [
                          const Icon(
                            Icons.swap_vert,
                            color: AppTheme.primaryGreen,
                          ),
                          const Icon(Icons.add, color: AppTheme.primaryGreen),
                        ],
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
                      child: ListView.separated(
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

          // Current Location Button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.5 + 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {},
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleItem(Map<String, dynamic> vehicle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(vehicle['icon'], style: const TextStyle(fontSize: 32)),
        ),
      ),
      title: Row(
        children: [
          Text(
            vehicle['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(Icons.person, size: 14, color: Colors.grey[600]),
          Text(
            ' ${vehicle['seats']} • ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Icon(Icons.bolt, size: 14, color: Colors.orange),
          Text(
            ' Đón trong ${vehicle['time']}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (vehicle['promo'] != null) ...[
            const SizedBox(width: 8),
            Text(
              vehicle['promo'],
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${vehicle['price']}đ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (vehicle['oldPrice'] != null)
            Text(
              '${vehicle['oldPrice']}đ',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
        ],
      ),
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
      child: Row(
        children: [
          const Icon(Icons.discount, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: const [
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'XanhNow',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đặt xe',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
