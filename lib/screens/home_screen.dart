import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../theme/app_theme.dart';
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

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<Map<String, dynamic>> _pickupSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDestinationSuggestions = false;

  String _distance = '';
  String _duration = '';
  String _fare = '';
  String _selectedVehicleType = 'car';
  bool _showVehicleOptions = false;

  static const String GOONG_API_KEY =
      'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ';

  Future<LatLng?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    try {
      final String url =
          'https://rsapi.goong.io/geocode?address=${Uri.encodeComponent(address)}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['results'] != null && json['results'].isNotEmpty) {
          final location = json['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Lỗi geocode: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getPlaceSuggestions(String input) async {
    if (input.isEmpty) return [];

    try {
      final String url =
          'https://rsapi.goong.io/Place/AutoComplete?input=${Uri.encodeComponent(input)}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['predictions'] != null) {
          return List<Map<String, dynamic>>.from(json['predictions']);
        }
      }
    } catch (e) {
      print('Lỗi lấy gợi ý: $e');
    }
    return [];
  }

  Future<void> _getRoute() async {
    if (_pickupLatLng == null || _destinationLatLng == null) return;

    try {
      final String url =
          'https://rsapi.goong.io/Direction?origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&destination=${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}&vehicle=car&api_key=$GOONG_API_KEY';

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

          String distanceStr = totalDistance > 0
              ? '${totalDistance.toStringAsFixed(1)} km'
              : 'N/A';

          int minutes = (totalDuration / 60).toInt();
          String durationStr = minutes > 0
              ? '$minutes phút'
              : '${totalDuration.toInt()}s';

          double fareAmount = 0;
          if (totalDistance <= 5) {
            fareAmount = (totalDistance * 1000 / 100) * 1100;
          } else {
            fareAmount = (totalDistance * 1000 / 100) * 1000;
          }
          String fareStr = '${fareAmount.toStringAsFixed(0)} VND';

          setState(() {
            _distance = distanceStr;
            _duration = durationStr;
            _fare = fareStr;
            _polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: AppTheme.primaryGreen,
                width: 5,
                geodesic: true,
              ),
            };
          });
        }
      }
    } catch (e) {
      print('Lỗi lấy route: $e');
    }
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
          _distance = '';
          _duration = '';
          _fare = '';
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
        });

        await _getRoute();
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

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_mapController != null && mounted) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            100,
          ),
        );
      }
    });
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

  void _handlePickupChange(String value) {
    _pickupLocation = value;
    _updateRoute();

    if (value.isNotEmpty) {
      _getPickupSuggestions(value);
    } else {
      setState(() {
        _pickupSuggestions.clear();
        _showPickupSuggestions = false;
      });
    }
  }

  void _handleDestinationChange(String value) {
    _destinationLocation = value;

    if (value.isNotEmpty) {
      _getDestinationSuggestions(value);
    } else {
      setState(() {
        _destinationSuggestions.clear();
        _showDestinationSuggestions = false;
      });
    }

    _updateRoute();
  }

  Future<void> _getPickupSuggestions(String input) async {
    final suggestions = await _getPlaceSuggestions(input);
    setState(() {
      _pickupSuggestions = suggestions;
      _showPickupSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _getDestinationSuggestions(String input) async {
    final suggestions = await _getPlaceSuggestions(input);
    setState(() {
      _destinationSuggestions = suggestions;
      _showDestinationSuggestions = suggestions.isNotEmpty;
    });
  }

  double _calculateFareByType(String vehicleType) {
    double distance = double.tryParse(_distance.split(' ')[0]) ?? 0;

    if (vehicleType == 'bike') {
      return (distance * 1000 / 100) * 500;
    } else if (vehicleType == 'car') {
      if (distance <= 5) {
        return (distance * 1000 / 100) * 1100;
      } else {
        return (distance * 1000 / 100) * 1000;
      }
    } else if (vehicleType == 'delivery') {
      return (distance * 1000 / 100) * 1000;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            child: Container(
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
                      icon: const Icon(Icons.menu, color: AppTheme.darkGrey),
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
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildLocationField(
                            controller: _pickupController,
                            hint: 'Điểm đi',
                            icon: Icons.location_on,
                            onChanged: _handlePickupChange,
                            suggestions: _pickupSuggestions,
                            showSuggestions: _showPickupSuggestions,
                            onSuggestionSelected: (suggestion) {
                              _pickupController.text =
                                  suggestion['description'] ?? '';
                              _handlePickupChange(
                                suggestion['description'] ?? '',
                              );
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _showPickupSuggestions = false;
                              });
                            },
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.lightGrey,
                            indent: 16,
                            endIndent: 16,
                          ),
                          _buildLocationField(
                            controller: _destinationController,
                            hint: 'Điểm đến',
                            icon: Icons.location_on,
                            onChanged: _handleDestinationChange,
                            suggestions: _destinationSuggestions,
                            showSuggestions: _showDestinationSuggestions,
                            onSuggestionSelected: (suggestion) {
                              setState(() {
                                _destinationSuggestions.clear();
                                _showDestinationSuggestions = false;
                              });
                              _destinationController.text =
                                  suggestion['description'] ?? '';
                              _destinationLocation =
                                  suggestion['description'] ?? '';
                              _updateRoute();
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ],
                      ),
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
                    if (_distance.isNotEmpty && _duration.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryGreen,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _distance,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _duration,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.local_taxi,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fare,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showVehicleOptions && _distance.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn loại xe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildVehicleOption(
                          'bike',
                          '🏍️ Xe máy',
                          _calculateFareByType('bike'),
                        ),
                        _buildVehicleOption(
                          'car',
                          '🚗 Ô tô',
                          _calculateFareByType('car'),
                        ),
                        _buildVehicleOption(
                          'delivery',
                          '🚚 Giao hàng',
                          _calculateFareByType('delivery'),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showVehicleOptions = !_showVehicleOptions;
                    });
                  },
                  child: BottomBookButton(onPressed: _onBookRide),
                ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: 100,
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

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    required List<Map<String, dynamic>> suggestions,
    required bool showSuggestions,
    required Function(Map<String, dynamic>) onSuggestionSelected,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.lightGrey),
              prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
              border: InputBorder.none,
            ),
          ),
        ),
        if (showSuggestions)
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length > 5 ? 5 : suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    suggestion['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => onSuggestionSelected(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleOption(String type, String label, double fare) {
    bool isSelected = _selectedVehicleType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryGreen,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppTheme.white : AppTheme.darkGrey,
              ),
            ),
            Text(
              '${fare.toStringAsFixed(0)} VND',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppTheme.white : AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
