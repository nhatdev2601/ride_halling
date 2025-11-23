import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/location_input.dart';
import '../widgets/bottom_book_button.dart';
import 'vehicle_selection_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _pickupLocation = '';
  String _destinationLocation = '';

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(10.762622, 106.660172);

  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  Timer? _debounce;
  bool _isLoadingRoute = false;

  static const String apiKey = 'AIzaSyDgVoRC7xtqrRixaQRTHKcxRLTon-RXpug';

  // 🌍 Lấy tọa độ từ Place ID (chính xác hơn)
  Future<LatLng?> _getLatLngFromPlaceId(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      const String baseUrl =
          'https://maps.googleapis.com/maps/api/place/details/json';

      final String url =
          '$baseUrl?place_id=$placeId&fields=geometry&key=$apiKey';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['result'] != null) {
          final location = json['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Lỗi lấy Place ID: $e');
    }
    return null;
  }

  // 🌍 Fallback: Geocode từ địa chỉ text
  Future<LatLng?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey&components=country:vn';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['results'].isNotEmpty) {
          final location = json['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Lỗi geocode: $e');
    }
    return null;
  }

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

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    } catch (e) {
      _showError('Lỗi lấy vị trí: ${e.toString()}');
    }
  }

  void _updateRoute() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 1), () async {
      if (_pickupLocation.isEmpty || _destinationLocation.isEmpty) {
        setState(() {
          _polylines.clear();
          _markers.clear();
        });
        return;
      }

      setState(() {
        _isLoadingRoute = true;
      });

      _pickupLatLng = await _geocodeAddress(_pickupLocation);
      _destinationLatLng = await _geocodeAddress(_destinationLocation);

      if (_pickupLatLng != null && _destinationLatLng != null) {
        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('pickup'),
              position: _pickupLatLng!,
              infoWindow: const InfoWindow(title: 'Điểm đi'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('destination'),
              position: _destinationLatLng!,
              infoWindow: const InfoWindow(title: 'Điểm đến'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          };

          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [_pickupLatLng!, _destinationLatLng!],
              color: AppTheme.primaryGreen,
              width: 5,
              geodesic: true,
            ),
          };
        });

        _zoomToFitMarkers();
      } else {
        _showError('Không thể tìm được một trong hai địa chỉ');
      }

      setState(() {
        _isLoadingRoute = false;
      });
    });
  }

  void _zoomToFitMarkers() {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    double minLat = (_pickupLatLng!.latitude < _destinationLatLng!.latitude)
        ? _pickupLatLng!.latitude
        : _destinationLatLng!.latitude;
    double minLng = (_pickupLatLng!.longitude < _destinationLatLng!.longitude)
        ? _pickupLatLng!.longitude
        : _destinationLatLng!.longitude;
    double maxLat = (_pickupLatLng!.latitude >= _destinationLatLng!.latitude)
        ? _pickupLatLng!.latitude
        : _destinationLatLng!.latitude;
    double maxLng = (_pickupLatLng!.longitude >= _destinationLatLng!.longitude)
        ? _pickupLatLng!.longitude
        : _destinationLatLng!.longitude;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  void _onBookRide() {
    if (_pickupLocation.isNotEmpty && _destinationLocation.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleSelectionScreen(
            pickupLocation: _pickupLocation,
            destinationLocation: _destinationLocation,
          ),
        ),
      );
    } else {
      _showError('Vui lòng nhập điểm đi và điểm đến');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            liteModeEnabled: false,
            polylines: _polylines,
            markers: _markers,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: AppTheme.darkGrey,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'RideApp',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.person_outline,
                              color: AppTheme.darkGrey,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  LocationInput(
                    onPickupChanged: (value) {
                      _pickupLocation = value;
                      _updateRoute();
                    },
                    onDestinationChanged: (value) {
                      _destinationLocation = value;
                      _updateRoute();
                    },
                  ),

                  if (_isLoadingRoute)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 20,
                        child: LinearProgressIndicator(
                          backgroundColor: AppTheme.lightGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
               child: BottomBookButton(onPressed: _onBookRide),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.white,
              onPressed: _getCurrentLocation,
              child: const Icon(
                Icons.my_location,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
