import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/config.dart'; // Đảm bảo bạn có file config này

// ==========================================================
// 1. MODELS (Mô hình Dữ liệu)
// ==========================================================

/// Model Ride (dựa trên các trường trả về từ rides_by_status)
class Ride {
  final String id;
  final String status;
  final double totalFare;
  final String? driverId;
  final String? passengerId;
  final DateTime? createdAt;

  Ride({
    required this.id,
    required this.status,
    required this.totalFare,
    this.driverId,
    this.passengerId,
    this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['ride_id']?.toString() ?? 'N/A',
      status: json['status'] ?? 'unknown',
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 0.0,
      driverId: json['driver_id']?.toString(),
      passengerId: json['passenger_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

/// Model cho User cơ bản (Fetch từ /api/admin/users/{userId})
class UserBasic {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String status;

  UserBasic({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.status,
  });

  factory UserBasic.fromJson(Map<String, dynamic> json) {
    // Giả định các trường trả về: user_id, full_name, email, phone_number, status
    return UserBasic(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? 'N/A',
      fullName: json['fullName'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'N/A',
      phoneNumber: json['phone'] as String? ?? 'N/A',
      status: (json['status'] as String? ?? 'unknown').toLowerCase(),
    );
  }
}

// ==========================================================
// 2. WIDGET (Giao diện Người dùng)
// ==========================================================

class RideMonitoringPage extends StatefulWidget {
  const RideMonitoringPage({super.key});

  @override
  State<RideMonitoringPage> createState() => _RideMonitoringPageState();
}

class _RideMonitoringPageState extends State<RideMonitoringPage> {
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _statusFilterController = TextEditingController();
  List<Ride> _activeRides = [];
  int _activeRidesTotal = 0;
  List<Ride> _driverRides = [];
  bool _isLoadingActive = false;
  bool _isLoadingDriver = false;

  static const String _baseUrl = '${AppConfig.baseUrl}/api/admin';
  static const Map<String, String> _headers = {
    'Authorization': 'Bearer YOUR_ADMIN_TOKEN', // THAY THẾ BẰNG TOKEN CỦA BẠN
    'Content-Type': 'application/json',
  };

  @override
  void initState() {
    super.initState();
    _loadRides(status: null, isInitialLoad: true);
  }

  // --- Hàm Tiện ích & UI Helpers ---

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requesting':
        return Colors.blue;
      case 'accepted':
        return Colors.cyan;
      case 'arrived':
        return Colors.lime;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Hàm helper cho màu User Status (Dùng chung với _getStatusColor)
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

  // Helper Widget để hiển thị dòng chi tiết (căn chỉnh thẳng hàng)
  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // Cố định chiều rộng nhãn
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- Hàm Fetch và Show User Detail (MỚI) ---
  Future<void> _fetchAndShowUserDetail(
    String userId,
    String userRole,
    BuildContext parentContext,
  ) async {
    // Hiển thị Dialog Loading trước
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Loading $userRole details...'),
          ],
        ),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'), // API User Detail
        headers: _headers,
      );

      // Đóng Dialog Loading
      Navigator.pop(parentContext);

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final user = UserBasic.fromJson(userData);

        Color userStatusColor = _getUserStatusColor(user.status);

        // Hiển thị Dialog chứa thông tin User
        showDialog(
          context: parentContext,
          builder: (context) => AlertDialog(
            title: Text('$userRole Details: ${user.fullName}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Tên', user.fullName, Colors.black),
                  _buildDetailRow('Email', user.email, Colors.black),
                  _buildDetailRow('Phone', user.phoneNumber, Colors.black),
                  _buildDetailRow(
                    'Status',
                    user.status.toUpperCase(),
                    userStatusColor,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar(
          'Failed to load $userRole details. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Đóng Dialog Loading nếu có lỗi (tránh crash)
      if (Navigator.canPop(parentContext)) Navigator.pop(parentContext);
      _showSnackBar('Error fetching $userRole details: $e');
    }
  }

  // Hàm Widget cho nút User/Driver Info
  Widget _buildUserApiButton(String label, String userId, Color color) {
    String role = label.contains('Passenger') ? 'Passenger' : 'Driver';
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => _fetchAndShowUserDetail(
          userId,
          role,
          context,
        ), // GỌI HÀM FETCH THẬT
        icon: const Icon(Icons.person_search, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // Hàm hiển thị Dialog chi tiết chuyến đi
  void _viewRideDetail(Ride ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ride Detail: ${ride.id.substring(0, 8)}...'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Status',
                ride.status,
                _getStatusColor(ride.status),
              ),
              _buildDetailRow(
                'Total Fare',
                '\$${ride.totalFare.toStringAsFixed(2)}',
                Colors.black,
              ),
              _buildDetailRow(
                'Requested At',
                ride.createdAt?.toLocal().toString() ?? 'N/A',
                Colors.black,
              ),
              const Divider(),
              _buildDetailRow(
                'Passenger ID',
                ride.passengerId ?? 'N/A',
                Colors.indigo,
              ),
              if (ride.driverId != null)
                _buildDetailRow('Driver ID', ride.driverId!, Colors.teal),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  if (ride.passengerId != null)
                    _buildUserApiButton(
                      'View Passenger Info',
                      ride.passengerId!,
                      Colors.indigo,
                    ),
                  if (ride.driverId != null)
                    _buildUserApiButton(
                      'View Driver Info',
                      ride.driverId!,
                      Colors.teal,
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCancelDialog(ride.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Force Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String rideId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Cancel Ride'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for cancellation',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                _forceCancelRide(rideId, reasonController.text);
                Navigator.pop(context);
              } else {
                _showSnackBar('Reason is required');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // --- Hàm API Calls (Giữ nguyên) ---

  Future<void> _loadRides({String? status, bool isInitialLoad = false}) async {
    setState(() {
      _isLoadingActive = true;
      if (!isInitialLoad) {
        _activeRides = [];
        _activeRidesTotal = 0;
      }
    });

    String url = '$_baseUrl/rides/active';
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['rides'] ?? [];

        setState(() {
          _activeRides = data.map((json) => Ride.fromJson(json)).toList();
          _activeRidesTotal = responseData['total'] ?? 0;
        });
        _showSnackBar(
          'Loaded ${_activeRides.length} rides. Status: ${status ?? 'All Active'}',
        );
      } else {
        _showSnackBar('Failed to load rides (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Error loading rides: $e');
    } finally {
      setState(() {
        _isLoadingActive = false;
      });
    }
  }

  Future<void> _getDriverRides(String driverId) async {
    setState(() {
      _isLoadingDriver = true;
      _driverRides = [];
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId/rides?limit=20'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['rides'] ?? [];

        setState(() {
          _driverRides = data.map((json) => Ride.fromJson(json)).toList();
        });
        _showSnackBar(
          'Loaded ${_driverRides.length} rides for Driver ${driverId.substring(0, 8)}...',
        );
      } else {
        _showSnackBar(
          'Failed to load driver rides (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      _showSnackBar('Error loading driver rides: $e');
    } finally {
      setState(() {
        _isLoadingDriver = false;
      });
    }
  }

  Future<void> _forceCancelRide(String rideId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rides/$rideId/force-cancel'),
        headers: _headers,
        body: jsonEncode({'reason': reason}),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Ride $rideId cancelled successfully.');
        _loadRides(status: _statusFilterController.text);
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(
          'Failed to cancel: ${error['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Ride Monitoring 📊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingActive ? null : () => _loadRides(status: null),
            tooltip: 'Load All Active Rides',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row chứa nút Load All và TextField Filter
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingActive
                        ? null
                        : () => _loadRides(status: null),
                    icon: const Icon(Icons.list),
                    label: const Text(
                      'All Active',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _statusFilterController,
                    decoration: InputDecoration(
                      labelText: 'Filter Status (e.g., in_progress)',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_list, size: 20),
                        onPressed: () => _loadRides(
                          status: _statusFilterController.text.trim(),
                        ),
                      ),
                    ),
                    onSubmitted: (value) => _loadRides(status: value.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tìm driver rides
            TextField(
              controller: _driverIdController,
              decoration: const InputDecoration(
                labelText: 'Driver ID for Past Rides',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _getDriverRides,
            ),
            const SizedBox(height: 20),

            // Active Rides List
            Text(
              'Active Rides (Showing ${_activeRides.length} of $_activeRidesTotal):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Expanded(
              flex: 1,
              child: _isLoadingActive
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _activeRides.length,
                      itemBuilder: (context, index) {
                        final ride = _activeRides[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          elevation: 2,
                          child: ListTile(
                            onTap: () =>
                                _viewRideDetail(ride), // Mở detail dialog
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(ride.status),
                              child: Text(
                                ride.status[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              'Status: ${ride.status}',
                              style: TextStyle(
                                color: _getStatusColor(ride.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Fare: \$${ride.totalFare.toStringAsFixed(2)} | Passenger: ${ride.passengerId?.substring(0, 8) ?? 'N/A'}...',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _showCancelDialog(ride.id),
                              tooltip: 'Force Cancel',
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 20),

            // Driver Rides List
            Text(
              'Driver Past Rides (Found: ${_driverRides.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Expanded(
              flex: 1,
              child: _isLoadingDriver
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _driverRides.length,
                      itemBuilder: (context, index) {
                        final ride = _driverRides[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(ride.status),
                              child: Text(
                                ride.status[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              'Status: ${ride.status}',
                              style: TextStyle(
                                color: _getStatusColor(ride.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Created: ${ride.createdAt?.toLocal().toString().split(' ')[0] ?? 'N/A'} | Fare: \$${ride.totalFare.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
