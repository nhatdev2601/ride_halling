import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import 'vehicle_selection_map_screen.dart';
import 'location_search_screen.dart';
class PickupConfirmationScreen extends StatefulWidget {
  final String pickupAddress;
  final LatLng pickupLatLng;
  final String destinationAddress;
  final LatLng destinationLatLng; // ✅ Đổi thành non-nullable

  const PickupConfirmationScreen({
    super.key,
    required this.pickupAddress,
    required this.pickupLatLng,
    required this.destinationAddress,
    required this.destinationLatLng, // ✅ Required, không nullable
  });

  @override
  State<PickupConfirmationScreen> createState() =>
      _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  void _confirmPickup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSelectionMapScreen(
          pickupAddress: widget.pickupAddress,
          pickupLatLng: widget.pickupLatLng,
          destinationAddress: widget.destinationAddress,
          destinationLatLng: widget.destinationLatLng,
        ),
      ),
    );
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
              zoom: 16,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pickupAddress.split(',').first,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.pickupAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
IconButton(
  icon: const Icon(Icons.edit, color: Colors.grey),
  onPressed: () async {
    // ✅ Chuyển đến màn hình LocationSearchScreen và truyền điểm đến hiện tại
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          initialDestination: widget.destinationAddress, // ✅ Truyền điểm đến hiện tại
        ),
      ),
    );

    // ✅ Nếu người dùng chọn điểm đến mới, reload màn hình với dữ liệu mới
    if (result != null && result is Map<String, dynamic>) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PickupConfirmationScreen(
            pickupAddress: widget.pickupAddress,
            pickupLatLng: widget.pickupLatLng,
            destinationAddress: result['address'],
            destinationLatLng: result['latLng'],
          ),
        ),
      );
    }
  },
),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Icon(
                            Icons.note_add_outlined,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Thêm ghi chú cho bác tài (ví dụ: gần cổng).',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _confirmPickup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận điểm đón',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
