import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/config.dart';

// ==========================================================
// 1. MODELS (Mô hình Dữ liệu)
// ==========================================================

/// Model cho User cơ bản (từ bảng users)
class UserBasic {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String userType;
  final String status;

  UserBasic({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.status,
  });

  factory UserBasic.fromJson(Map<String, dynamic> json) {
    // Giả định mapping từ C# DTO
    return UserBasic(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? 'N/A',
      fullName: json['full_name'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'N/A',
      phoneNumber: json['phone_number'] as String? ?? 'N/A',
      userType: json['user_type'] as String? ?? 'N/A',
      status: (json['status'] as String? ?? 'unknown').toLowerCase(),
    );
  }
}

/// Model đầy đủ cho một Driver (thông tin chuyên môn)
class Driver {
  final String driverId;
  final String userId;
  final int completedTrips;
  final bool isAvailable;
  final String onlineStatus;
  final double rating;
  final double totalEarnings;
  final double? currentLocationLat;
  final double? currentLocationLng;
  final String licenseNumber;
  final String licenseExpiry;
  final String createdAt;
  final String updatedAt;

  Driver({
    required this.driverId,
    required this.userId,
    required this.completedTrips,
    required this.isAvailable,
    required this.onlineStatus,
    required this.rating,
    required this.totalEarnings,
    this.currentLocationLat,
    this.currentLocationLng,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverId: json['driver_id'] as String,
      userId: json['user_id'] as String,
      completedTrips: json['completed_trips'] as int,
      isAvailable: json['is_available'] as bool,
      onlineStatus: json['online_status'] as String,
      rating: (json['rating'] as num).toDouble(),
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      currentLocationLat: (json['current_location_lat'] as num?)?.toDouble(),
      currentLocationLng: (json['current_location_lng'] as num?)?.toDouble(),
      licenseNumber: json['license_number'] as String,
      licenseExpiry: json['license_expiry'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Driver copyWith({String? userId}) {
    return Driver(
      driverId: driverId,
      userId: userId ?? this.userId,
      completedTrips: completedTrips,
      isAvailable: isAvailable,
      onlineStatus: onlineStatus,
      rating: rating,
      totalEarnings: totalEarnings,
      currentLocationLat: currentLocationLat,
      currentLocationLng: currentLocationLng,
      licenseNumber: licenseNumber,
      licenseExpiry: licenseExpiry,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Model tổng hợp Driver và User
class DriverDetail {
  final Driver driver;
  final UserBasic? user;

  DriverDetail({required this.driver, this.user});

  DriverDetail copyWith({Driver? driver, UserBasic? user}) {
    return DriverDetail(driver: driver ?? this.driver, user: user ?? this.user);
  }
}

/// Model đơn giản cho Driver khi tìm kiếm theo Vị trí (Geohash)
class DriverByLocation {
  final String id;
  final String name;
  final String geohash;

  DriverByLocation({
    required this.id,
    required this.name,
    required this.geohash,
  });

  factory DriverByLocation.fromJson(Map<String, dynamic> json) {
    return DriverByLocation(
      id: json['driver_id'] as String? ?? json['id'].toString(),
      name: json['name'] ?? 'No Name',
      geohash: json['geohash'] ?? 'N/A',
    );
  }
}

/// Model đơn giản cho Rides (Lấy từ /drivers/{id}/rides)
class Ride {
  final String id;
  final String status;
  final double totalFare;
  final DateTime? createdAt;

  Ride({
    required this.id,
    required this.status,
    required this.totalFare,
    this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['ride_id']?.toString() ?? 'N/A',
      status: json['status'] ?? 'unknown',
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

// ==========================================================
// 2. WIDGET (Giao diện Người dùng)
// ==========================================================

class DriverManagementPage extends StatefulWidget {
  const DriverManagementPage({super.key});

  @override
  State<DriverManagementPage> createState() => _DriverManagementPageState();
}

class _DriverManagementPageState extends State<DriverManagementPage> {
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _geohashController = TextEditingController();

  List<DriverDetail> _allDriverDetails = [];
  bool _isLoadingAllDrivers = false;

  DriverDetail? _selectedDriverDetail;
  List<DriverByLocation> _driversByLocation = [];

  List<Ride> _selectedDriverRides = [];
  bool _isLoadingDriverRides = false;

  static const String _baseUrl = '${AppConfig.baseUrl}/api/admin';
  static const Map<String, String> _headers = {
    'Authorization': 'Bearer YOUR_ADMIN_TOKEN',
    'Content-Type': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _getAllDrivers();
  }

  // --- Hàm Tiện ích ---

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getUserStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRideStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
      case 'accepted':
      case 'requesting':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // --- Hàm API Lấy User (Helper Function) ---
  Future<UserBasic?> _fetchUserByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        // Cần đảm bảo UserBasic.fromJson khớp với response thực tế
        return UserBasic.fromJson(jsonDecode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // --- Hàm API Cập nhật User Status ---
  Future<void> _updateUserStatus(String userId, String status) async {
    final normalizedStatus = status.toLowerCase();

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/status'),
        headers: _headers,
        body: jsonEncode({'status': normalizedStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Cập nhật selected driver detail
          if (_selectedDriverDetail != null &&
              _selectedDriverDetail!.driver.userId == userId) {
            final oldUser = _selectedDriverDetail!.user;
            if (oldUser != null) {
              final newUser = UserBasic(
                userId: oldUser.userId,
                fullName: oldUser.fullName,
                email: oldUser.email,
                phoneNumber: oldUser.phoneNumber,
                userType: oldUser.userType,
                status: normalizedStatus,
              );
              _selectedDriverDetail = _selectedDriverDetail!.copyWith(
                user: newUser,
              );
            }
          }
          // Cập nhật trong danh sách tất cả drivers
          final index = _allDriverDetails.indexWhere(
            (d) => d.driver.userId == userId,
          );
          if (index != -1) {
            final oldDetail = _allDriverDetails[index];
            final oldUser = oldDetail.user;
            if (oldUser != null) {
              final newUser = UserBasic(
                userId: oldUser.userId,
                fullName: oldUser.fullName,
                email: oldUser.email,
                phoneNumber: oldUser.phoneNumber,
                userType: oldUser.userType,
                status: normalizedStatus,
              );
              _allDriverDetails[index] = oldDetail.copyWith(user: newUser);
            }
          }
        });
        _showSnackBar('User $userId status updated to $normalizedStatus');
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(
          'Failed to update status: ${error['message'] ?? 'Unknown error'} (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      _showSnackBar('Error updating status: $e');
    }
  }

  // --- Hàm API Calls Rides ---

  Future<void> _getDriverRides(String driverId) async {
    setState(() {
      _isLoadingDriverRides = true;
      _selectedDriverRides = [];
    });
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/drivers/$driverId/rides?limit=10',
        ), // Lấy 10 chuyến gần nhất
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['rides'] ?? [];

        setState(() {
          _selectedDriverRides = data
              .map((json) => Ride.fromJson(json))
              .toList();
        });
        _showSnackBar('Loaded ${_selectedDriverRides.length} recent rides.');
      } else {
        _showSnackBar(
          'Failed to load driver rides. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('Error loading driver rides: $e');
    } finally {
      setState(() {
        _isLoadingDriverRides = false;
      });
    }
  }

  // --- Hàm API Calls chính ---

  Future<void> _getAllDrivers() async {
    setState(() {
      _isLoadingAllDrivers = true;
      _allDriverDetails = [];
      _selectedDriverDetail = null;
      _driversByLocation = [];
      _selectedDriverRides = []; // Reset Rides
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['drivers'] ?? [];

        List<DriverDetail> loadedDetails = [];

        await Future.wait(
          data.map((json) async {
            final driver = Driver.fromJson(json);
            final user = await _fetchUserByUserId(driver.userId);
            loadedDetails.add(DriverDetail(driver: driver, user: user));
          }),
        );

        setState(() {
          _allDriverDetails = loadedDetails;
        });
        _showSnackBar(
          'Fetched ${_allDriverDetails.length} drivers successfully (with User info).',
        );
      } else {
        _showSnackBar('Failed to load drivers. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error loading drivers: $e');
    } finally {
      setState(() {
        _isLoadingAllDrivers = false;
      });
    }
  }

  Future<void> _getDriverById(String id) async {
    setState(() {
      _selectedDriverDetail = null;
      _driversByLocation = [];
      _selectedDriverRides = []; // Reset Rides
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$id'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final driver = Driver.fromJson(jsonDecode(response.body));

        final user = await _fetchUserByUserId(driver.userId);

        setState(() {
          _selectedDriverDetail = DriverDetail(driver: driver, user: user);
        });
        _showSnackBar('Driver ID $id found.');

        // GỌI HÀM FETCH RIDES
        _getDriverRides(id);
      } else {
        _showSnackBar('Driver ID $id not found');
      }
    } catch (e) {
      _showSnackBar('Error searching by ID: $e');
    }
  }

  Future<void> _getDriversByGeohash(String geohash) async {
    setState(() {
      _selectedDriverDetail = null;
      _driversByLocation = [];
      _selectedDriverRides = []; // Reset Rides
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/location/$geohash'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _driversByLocation = data
              .map((json) => DriverByLocation.fromJson(json))
              .toList();
        });
        _showSnackBar(
          'Found ${_driversByLocation.length} drivers near $geohash.',
        );
      } else {
        _showSnackBar('No drivers found near $geohash');
      }
    } catch (e) {
      _showSnackBar('Error searching by Geohash: $e');
    }
  }

  // --- Helper Widgets ---

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // Định chiều rộng cố định cho label
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }

  Widget _buildDriverDetailCard(DriverDetail detail) {
    final driver = detail.driver;
    final user = detail.user;

    Color statusColor = driver.isAvailable ? Colors.green : Colors.red;
    Color userStatusColor = _getUserStatusColor(user?.status ?? 'unknown');

    return Card(
      elevation: 4,
      color: Colors.lightBlue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blue,
              ),
            ),
            const Divider(),

            // THÔNG TIN USER
            _buildDetailRow('Name:', user?.fullName ?? 'N/A (User Not Found)'),
            _buildDetailRow('Email:', user?.email ?? 'N/A'),
            _buildDetailRow('Phone:', user?.phoneNumber ?? 'N/A'),
            _buildDetailRow(
              'User Status:',
              user?.status ?? 'N/A',
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: userStatusColor,
              ),
            ),

            const Divider(height: 15),

            // CÁC NÚT ĐIỀU CHỈNH TRẠNG THÁI USER
            if (user != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateUserStatus(user.userId, 'active'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Activate',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateUserStatus(user.userId, 'suspended'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Suspend',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateUserStatus(user.userId, 'banned'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Ban',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const Divider(height: 15),

            // THÔNG TIN DRIVER CHUYÊN MÔN
            _buildDetailRow('Driver ID:', driver.driverId),
            _buildDetailRow(
              'Online Status:',
              '${driver.onlineStatus} (${driver.isAvailable ? 'Available' : 'Busy'})',
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            _buildDetailRow('Rating:', driver.rating.toStringAsFixed(2)),
            _buildDetailRow(
              'Completed Trips:',
              driver.completedTrips.toString(),
            ),
            _buildDetailRow(
              'Earnings:',
              '\$${driver.totalEarnings.toStringAsFixed(2)}',
            ),
            _buildDetailRow(
              'Location (Lat, Lng):',
              '${driver.currentLocationLat?.toStringAsFixed(4) ?? 'N/A'}, ${driver.currentLocationLng?.toStringAsFixed(4) ?? 'N/A'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverListByLocation() {
    return ListView.builder(
      itemCount: _driversByLocation.length,
      itemBuilder: (context, index) {
        final driver = _driversByLocation[index];
        return ListTile(
          title: Text(driver.name),
          subtitle: Text('ID: ${driver.id}'),
          trailing: Text(driver.geohash),
        );
      },
    );
  }

  Widget _buildDriverRidesList() {
    if (_isLoadingDriverRides) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Rides:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250, // Giới hạn chiều cao
          child: _selectedDriverRides.isEmpty
              ? const Center(child: Text('No recent rides found.'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedDriverRides.length,
                  itemBuilder: (context, index) {
                    final ride = _selectedDriverRides[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRideStatusColor(ride.status),
                          child: Text(ride.status[0].toUpperCase()),
                        ),
                        title: Text('Ride ID: ${ride.id.substring(0, 8)}...'),
                        subtitle: Text(
                          'Status: ${ride.status.toUpperCase()} | Fare: \$${ride.totalFare.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _getRideStatusColor(ride.status),
                          ),
                        ),
                        trailing: Text(
                          ride.createdAt?.toLocal().toString().split(' ')[0] ??
                              'N/A',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllDriversList() {
    if (_isLoadingAllDrivers) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    } else if (_allDriverDetails.isEmpty) {
      return const Expanded(child: Center(child: Text('No drivers found.')));
    } else {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Drivers (Total: ${_allDriverDetails.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _allDriverDetails.length,
                itemBuilder: (context, index) {
                  final detail = _allDriverDetails[index];
                  final driver = detail.driver;
                  final user = detail.user;

                  Color userStatusColor = _getUserStatusColor(
                    user?.status ?? 'unknown',
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedDriverDetail = detail;
                          _driversByLocation = [];
                        });
                        // GỌI HÀM FETCH RIDES KHI CHỌN TỪ DANH SÁCH
                        _getDriverRides(driver.driverId);
                      },
                      leading: CircleAvatar(
                        backgroundColor: driver.isAvailable
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          driver.rating.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        user?.fullName ??
                            'Driver ID: ${driver.driverId.substring(0, 8)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Email: ${user?.email ?? 'N/A'} | User Status: ${user?.status ?? 'N/A'}',
                        style: TextStyle(color: userStatusColor),
                      ),
                      trailing: Text('Trips: ${driver.completedTrips}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- Widget Build chính ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Driver Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingAllDrivers ? null : _getAllDrivers,
            tooltip: 'Refresh All Drivers',
          ),
        ],
      ),
      // Dùng SingleChildScrollView để xử lý cuộn khi Detail Card và Rides List hiện ra
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tìm driver by ID
              TextField(
                controller: _driverIdController,
                decoration: const InputDecoration(
                  labelText: 'Search Driver by ID',
                  suffixIcon: Icon(Icons.person_search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _getDriverById,
              ),
              const SizedBox(height: 10),

              // Tìm drivers by geohash (Giữ nguyên)
              TextField(
                controller: _geohashController,
                decoration: const InputDecoration(
                  labelText: 'Search Drivers by Geohash',
                  suffixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _getDriversByGeohash,
              ),
              const SizedBox(height: 20),

              // Hiển thị Driver được tìm kiếm theo ID (nếu có)
              if (_selectedDriverDetail != null) ...[
                _buildDriverDetailCard(_selectedDriverDetail!),
                const SizedBox(height: 20),

                // HIỂN THỊ DANH SÁCH CHUYẾN ĐI (MỚI)
                _buildDriverRidesList(),
                const SizedBox(height: 20),
              ],

              // Hiển thị Drivers được tìm kiếm theo Location (nếu có)
              if (_driversByLocation.isNotEmpty) ...[
                const Text(
                  'Drivers in Location:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 300, child: _buildDriverListByLocation()),
              ] else if (_selectedDriverDetail == null)
                // Danh sách TẤT CẢ DRIVERS (Chỉ hiển thị khi không có kết quả tìm kiếm chi tiết)
                // Cần bọc trong SizedBox có height vì Column cha là SingleChildScrollView
                SizedBox(height: 400, child: _buildAllDriversList()),
            ],
          ),
        ),
      ),
    );
  }
}
