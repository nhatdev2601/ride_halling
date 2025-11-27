import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/ride_service.dart';
import '../models/ride_models.dart';
import 'location_search_screen.dart';
import 'vehicle_selection_map_screen.dart'; //  Dùng màn hình có sẵn
import '../models/promotion_model.dart'; // Import model mới
import '../services/promotion_service.dart';

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

  List<PlaceSuggestion> _pickupSuggestions = [];
  List<PlaceSuggestion> _destinationSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDestinationSuggestions = false;

  String _distance = '';
  String _duration = '';
  String _fare = '';

  final LocationService _locationService = LocationService();
  final RideService _rideService = RideService();

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
    final result = await _locationService.getCurrentLocation();

    if (result.success && result.location != null) {
      setState(() {
        _currentPosition = result.location!;
        _pickupLocation = result.address ?? 'Vị trí hiện tại';
        //_pickupController.text = result.address ?? 'Vị trí hiện tại';
        _pickupLatLng = result.location;
      });

      print('========================================');
      print(' VỊ TRÍ HIỆN TẠI (Điểm đi)');
      print('========================================');
      print('Latitude:  ${result.location!.latitude}');
      print('Longitude: ${result.location!.longitude}');
      print('Địa chỉ:   ${result.address}');
      print('========================================\n');

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    } else {
      _showError(result.errorMessage ?? 'Không thể lấy vị trí');
    }
  }

  Future<void> _getPickupSuggestions(String input) async {
    final suggestions = await _locationService.getPlaceSuggestions(input);
    setState(() {
      _pickupSuggestions = suggestions;
      _showPickupSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _getDestinationSuggestions(String input) async {
    final suggestions = await _locationService.getPlaceSuggestions(input);
    setState(() {
      _destinationSuggestions = suggestions;
      _showDestinationSuggestions = suggestions.isNotEmpty;
    });
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

      _pickupLatLng = await _locationService.geocodeAddress(_pickupLocation);
      _destinationLatLng = await _locationService.geocodeAddress(
        _destinationLocation,
      );

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

        double distance = _locationService.calculateDistance(
          _pickupLatLng!,
          _destinationLatLng!,
        );
        setState(() {
          _distance = '${distance.toStringAsFixed(1)} km';
        });

        print('========================================');
        print(' DỮ LIỆU GỬI LÊN SERVER (JSON)');
        print('========================================');
        print('{');
        print('  "pickupLat": ${_pickupLatLng!.latitude},');
        print('  "pickupLng": ${_pickupLatLng!.longitude},');
        print('  "destinationLat": ${_destinationLatLng!.latitude},');
        print('  "destinationLng": ${_destinationLatLng!.longitude},');
        print('  "distance": ${distance.toStringAsFixed(2)},');
        print('  "pickupAddress": "$_pickupLocation",');
        print('  "destinationAddress": "$_destinationLocation"');
        print('}');
        print('========================================\n');

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

  //  Gọi API và chuyển sang màn hình chọn xe
  Future<void> _onBookRide() async {
    if (_pickupLatLng == null || _destinationLatLng == null) {
      _showError('Vui lòng chọn điểm đi và điểm đến');
      return;
    }

    // Chuyển sang màn hình chọn xe (dùng màn hình có sẵn)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSelectionMapScreen(
          pickupAddress: _pickupLocation,
          pickupLatLng: _pickupLatLng!,
          destinationAddress: _destinationLocation,
          destinationLatLng: _destinationLatLng!,
        ),
      ),
    );
  }

  final PromotionService _promotionService = PromotionService();
  List<Promotion> _promotions = [];
  bool _isLoadingPromos = true;
  @override
  void initState() {
    super.initState();
    print(' HomeScreen initState được gọi');
    _getCurrentLocation();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    final promos = await _promotionService.getActivePromotions();
    if (mounted) {
      setState(() {
        _promotions = promos;
        _isLoadingPromos = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print(' HomeScreen didChangeDependencies được gọi');
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
    print(' HomeScreen build được gọi');
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBox(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildServiceIcons(),
                    const SizedBox(height: 24),
                    _buildPromotionBanner(),
                    const SizedBox(height: 24),
                    _buildVoucherSection(),

                    //  Nút đặt xe
                    if (_pickupLatLng != null && _destinationLatLng != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _onBookRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Đặt xe - Khoảng cách: $_distance',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(20),
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
              icon: const Icon(Icons.person_outline, color: AppTheme.darkGrey),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
        );

        if (result != null) {
          setState(() {
            _pickupLocation = result['address'] ?? '';
            _pickupController.text = result['name'] ?? '';
          });
          _updateRoute();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pickupController.text.isEmpty
                    ? 'Bạn muốn đi đâu?'
                    : _pickupController.text,
                style: TextStyle(
                  color: _pickupController.text.isEmpty
                      ? Colors.grey[600]
                      : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildServiceIcon('🏍️', 'Bike', AppTheme.primaryGreen),
          _buildServiceIcon('🚗', 'Car', Colors.blue),
          _buildServiceIcon('🚚', 'Delivery', Colors.orange),
          _buildServiceIcon('🍽️', 'Food', Colors.red),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(String emoji, String label, Color color) {
    return InkWell(
      onTap: () {
        //  Chuyển sang màn hình tìm kiếm địa điểm
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              '🎉 Khuyến mãi đặc biệt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Giảm 50% cho chuyến đi đầu tiên',
              style: TextStyle(fontSize: 14, color: AppTheme.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ưu đãi dành cho bạn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: _isLoadingPromos
              ? const Center(child: CircularProgressIndicator()) // Loading...
              : _promotions.isEmpty
              ? const Center(child: Text("Chưa có mã khuyến mãi nào"))
              : ListView.builder(
                  // Dùng ListView.builder để render list động
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    final promo = _promotions[index];
                    // Lấy màu ngẫu nhiên cho đẹp
                    final color = _getVoucherColor(index);

                    return _buildVoucherCard(
                      promo.displayText, // VD: "Giảm 50%"
                      promo.description, // VD: "Đơn từ 0đ"
                      color,
                      promo
                          .promoCode, // Truyền thêm code để sau này bấm vào thì copy
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getVoucherColor(int index) {
    const colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  Widget _buildVoucherCard(
    String discount,
    String condition,
    Color color,
    String code,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            discount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            condition,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Hiển thị mã code nhỏ nhỏ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
