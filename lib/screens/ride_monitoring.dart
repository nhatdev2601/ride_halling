// ride_monitoring.dart - Giám sát Rides
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RideMonitoringPage extends StatefulWidget {
  const RideMonitoringPage({super.key});

  @override
  State<RideMonitoringPage> createState() => _RideMonitoringPageState();
}

class _RideMonitoringPageState extends State<RideMonitoringPage> {
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _rideIdController = TextEditingController();
  List<Ride> _activeRides = [];
  List<Ride> _driverRides = [];

  static const String _baseUrl = 'http://localhost:5000/api/admin';

  Future<void> _getActiveRides() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rides/active'),
        headers: {'Authorization': 'Bearer YOUR_ADMIN_TOKEN'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _activeRides = data.map((json) => Ride.fromJson(json)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _getDriverRides(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$driverId/rides?limit=20'),
        headers: {'Authorization': 'Bearer YOUR_ADMIN_TOKEN'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _driverRides = data.map((json) => Ride.fromJson(json)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _forceCancelRide(String rideId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rides/$rideId/force-cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_ADMIN_TOKEN',
        },
        body: jsonEncode({'reason': reason}),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Ride cancelled');
        _getActiveRides(); // Refresh
      } else {
        _showSnackBar('Failed to cancel');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Nút load active rides
          ElevatedButton(
            onPressed: _getActiveRides,
            child: const Text('Load Active Rides'),
          ),
          const SizedBox(height: 10),
          // Tìm driver rides
          TextField(
            controller: _driverIdController,
            decoration: const InputDecoration(
              labelText: 'Driver ID for Rides',
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: _getDriverRides,
          ),
          const SizedBox(height: 20),
          // Active Rides List
          const Text(
            'Active Rides:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _activeRides.length,
              itemBuilder: (context, index) {
                final ride = _activeRides[index];
                return ListTile(
                  title: Text('Ride ID: ${ride.id}'),
                  subtitle: Text(
                    'Status: ${ride.status} | Fare: \$${ride.totalFare}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _showCancelDialog(ride.id),
                  ),
                );
              },
            ),
          ),
          // Driver Rides List
          const Text(
            'Driver Rides:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _driverRides.length,
              itemBuilder: (context, index) {
                final ride = _driverRides[index];
                return ListTile(
                  title: Text('Ride ID: ${ride.id}'),
                  subtitle: Text('Status: ${ride.status}'),
                );
              },
            ),
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
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _forceCancelRide(rideId, reasonController.text);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// Model Ride (dựa trên backend)
class Ride {
  final String id;
  final String status;
  final double totalFare;

  Ride({required this.id, required this.status, required this.totalFare});

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['ride_id'].toString(),
      status: json['status'] ?? '',
      totalFare: (json['total_fare'] ?? 0).toDouble(),
    );
  }
}
