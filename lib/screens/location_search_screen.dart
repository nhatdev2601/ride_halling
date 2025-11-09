import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'pickup_confirmation_screen.dart';

class LocationSearchScreen extends StatefulWidget {
  final String? initialDestination; // ✅ Thêm tham số nhận điểm đến ban đầu

  const LocationSearchScreen({super.key, this.initialDestination});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // ✅ Thêm FocusNode cho điểm đi
  final FocusNode _destinationFocusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _showRecent = true;
  bool _isLoading = false;
  bool _isSearchingPickup = false; // ✅ Biết đang search ô nào

  LatLng? _currentPosition;

  static const String GOONG_API_KEY = 'pvIfGgG2YHiLHSQgg3WRGo4NVK0RDabyqH9k1HQQ';
  static const String DEFAULT_PICKUP_TEXT = 'Vị trí hiện tại';

  final List<Map<String, String>> _recentLocations = [
    {
      'name': 'Bến Xe Miền Tây',
      'address': '395 Đường Kinh Dương Vương, Phường An Lạc, Quận Bình Tân, Thành phố Hồ Chí Minh',
      'distance': '1,2 km',
    },
    {
      'name': 'Cổng 1 - Bến Xe Miền Tây',
      'address': '395 Đường Kinh Dương Vương, Phường An Lạc, Quận Bình Tân, Thành phố Hồ Chí Minh',
      'distance': '1,3 km',
    },
    {
      'name': 'Photoism.vn',
      'address': '437 Sư Vạn Hạnh, Phường 12, Quận 10, Thành phố Hồ Chí Minh',
      'distance': '5,4 km',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = DEFAULT_PICKUP_TEXT;
    
    if (widget.initialDestination != null) {
      _destinationController.text = widget.initialDestination!;
    }
    
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _searchFocusNode.unfocus();
      _destinationFocusNode.unfocus();
    });
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
    } catch (e) {
      _showError('Lỗi lấy vị trí: ${e.toString()}');
    }
  }

  Future<void> _getPlaceSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions.clear();
        _showRecent = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String url =
          'https://rsapi.goong.io/Place/AutoComplete?input=${Uri.encodeComponent(input)}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['predictions'] != null) {
          setState(() {
            _suggestions = List<Map<String, dynamic>>.from(json['predictions']);
            _showRecent = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Lỗi lấy gợi ý: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value, bool isPickup) {
    _debounce?.cancel();
    setState(() {
      _isSearchingPickup = isPickup;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getPlaceSuggestions(value);
    });
  }

  Future<LatLng?> _getLatLngFromPlaceId(String placeId) async {
    try {
      final String url =
          'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['result'] != null && json['result']['geometry'] != null) {
          final location = json['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Lỗi lấy LatLng: $e');
    }
    return null;
  }

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

  Future<String> _reverseGeocode(LatLng position) async {
    try {
      final String url =
          'https://rsapi.goong.io/Geocode?latlng=${position.latitude},${position.longitude}&api_key=$GOONG_API_KEY';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['results'] != null && json['results'].isNotEmpty) {
          return json['results'][0]['formatted_address'] ?? DEFAULT_PICKUP_TEXT;
        }
      }
    } catch (e) {
      print('Lỗi reverse geocode: $e');
    }
    return DEFAULT_PICKUP_TEXT;
  }

  void _selectLocation(String name, String address, {String? placeId}) async {
    // ✅ Nếu đang search điểm đi
    if (_isSearchingPickup) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );

      LatLng? pickupLatLng;
      if (placeId != null) {
        pickupLatLng = await _getLatLngFromPlaceId(placeId);
      }
      if (pickupLatLng == null) {
        pickupLatLng = await _geocodeAddress(address);
      }

      if (mounted) Navigator.pop(context);

      if (pickupLatLng != null) {
        setState(() {
          _currentPosition = pickupLatLng;
          _searchController.text = name; // ✅ Cập nhật TextField và AppBar
          _suggestions.clear();
          _showRecent = true;
        });
      } else {
        _showError('Không thể xác định vị trí điểm đi');
      }
      return;
    }

    // ✅ Xử lý khi chọn điểm đến (giữ nguyên logic cũ)
    bool isUsingCurrentLocation = (_searchController.text == DEFAULT_PICKUP_TEXT);

    LatLng? pickupLatLng;
    String pickupAddress;

    if (isUsingCurrentLocation) {
      if (_currentPosition == null) {
        _showError('Đang lấy vị trí hiện tại, vui lòng đợi...');
        await _getCurrentLocation();
        
        if (_currentPosition == null) {
          _showError('Không thể xác định vị trí hiện tại');
          return;
        }
      }

      pickupLatLng = _currentPosition;
      pickupAddress = await _reverseGeocode(_currentPosition!);
    } else {
      pickupLatLng = await _geocodeAddress(_searchController.text);
      pickupAddress = _searchController.text;

      if (pickupLatLng == null) {
        _showError('Không thể xác định vị trí điểm đi');
        return;
      }
    }

    if (pickupLatLng == null) {
      _showError('Không thể xác định vị trí điểm đi');
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );

    LatLng? tempDestinationLatLng;

    if (placeId != null) {
      tempDestinationLatLng = await _getLatLngFromPlaceId(placeId);
    }

    if (tempDestinationLatLng == null) {
      tempDestinationLatLng = await _geocodeAddress(address);
    }

    if (mounted) Navigator.pop(context);

    if (tempDestinationLatLng == null) {
      _showError('Không thể xác định vị trí điểm đến');
      return;
    }

    final LatLng finalPickupLatLng = pickupLatLng;
    final LatLng finalDestinationLatLng = tempDestinationLatLng;

    if (mounted) {
      if (widget.initialDestination != null) {
        Navigator.pop(context, {
          'address': address,
          'latLng': finalDestinationLatLng,
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PickupConfirmationScreen(
              pickupAddress: pickupAddress,
              pickupLatLng: finalPickupLatLng,
              destinationAddress: address,
              destinationLatLng: finalDestinationLatLng,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _destinationController.dispose();
    _searchFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black,
              child: const Icon(Icons.location_on, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _searchController.text == DEFAULT_PICKUP_TEXT
                    ? 'Vị trí hiện tại'
                    : 'Từ: ${_searchController.text.split(',').first}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          enableInteractiveSelection: false,
                          decoration: const InputDecoration(
                            hintText: 'Vị trí hiện tại',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) => _onSearchChanged(value, true), // ✅ isPickup = true
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 1),

                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _destinationController,
                          focusNode: _destinationFocusNode,
                          enableInteractiveSelection: false,
                          decoration: const InputDecoration(
                            hintText: 'Tới điểm?',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) => _onSearchChanged(value, false), // ✅ isPickup = false
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGreen,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.cyan[400],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTab('Đề xuất', _showRecent),
                  const SizedBox(width: 12),
                  _buildTab('Đã lưu', !_showRecent),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _showRecent ? _buildRecentList() : _buildSuggestionsList(),
            ),

            Container(
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
              child: InkWell(
                onTap: () {},
                child: Row(
                  children: const [
                    Icon(Icons.map_outlined, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Chọn từ bản đồ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRecentList() {
    return Column(
      children: [
        ..._recentLocations.map((location) => _buildLocationItem(location['name']!, location['address']!, location['distance']!)),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.map_outlined, color: Colors.grey),
          title: const Text('Không có địa điểm bạn cần?', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Hãy tạo địa điểm mới. Cùng xây dựng bản đồ hoàn hảo cho mọi chuyến đi!', style: TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty && !_isLoading) {
      return const Center(child: Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildLocationItem(
          suggestion['structured_formatting']?['main_text'] ?? 'Unknown',
          suggestion['description'] ?? '',
          '',
          placeId: suggestion['place_id'],
        );
      },
    );
  }

  Widget _buildLocationItem(String name, String address, String distance, {String? placeId}) {
    return ListTile(
      leading: const Icon(Icons.history, color: Colors.grey),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (distance.isNotEmpty) Text(distance, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(address, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: const Icon(Icons.more_vert, color: Colors.grey),
      onTap: () => _selectLocation(name, address, placeId: placeId),
    );
  }
}
