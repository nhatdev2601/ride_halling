// driver_management.dart - Quản lý Drivers
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverManagementPage extends StatefulWidget {
  const DriverManagementPage({super.key});

  @override
  State<DriverManagementPage> createState() => _DriverManagementPageState();
}

class _DriverManagementPageState extends State<DriverManagementPage> {
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _geohashController = TextEditingController();
  Driver? _selectedDriver;
  List<DriverByLocation> _driversByLocation = [];

  static const String _baseUrl = 'http://localhost:5000/api/admin';

  Future<void> _getDriverById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/$id'),
        headers: {'Authorization': 'Bearer YOUR_ADMIN_TOKEN'},
      );
      if (response.statusCode == 200) {
        final driver = Driver.fromJson(jsonDecode(response.body));
        setState(() {
          _selectedDriver = driver;
        });
      } else {
        _showSnackBar('Driver not found');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _getDriversByGeohash(String geohash) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers/location/$geohash'),
        headers: {'Authorization': 'Bearer YOUR_ADMIN_TOKEN'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _driversByLocation = data
              .map((json) => DriverByLocation.fromJson(json))
              .toList();
        });
      } else {
        _showSnackBar('No drivers found');
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tìm driver by ID
          TextField(
            controller: _driverIdController,
            decoration: const InputDecoration(
              labelText: 'Search Driver by ID',
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: _getDriverById,
          ),
          const SizedBox(height: 10),
          // Tìm drivers by geohash
          TextField(
            controller: _geohashController,
            decoration: const InputDecoration(
              labelText: 'Search Drivers by Geohash',
              suffixIcon: Icon(Icons.location_on),
            ),
            onSubmitted: _getDriversByGeohash,
          ),
          const SizedBox(height: 20),
          // Hiển thị driver info
          if (_selectedDriver != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${_selectedDriver!.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${_selectedDriver!.name}'),
                    Text('Status: ${_selectedDriver!.status}'),
                  ],
                ),
              ),
            ),
          ],
          // List drivers by location
          if (_driversByLocation.isNotEmpty) ...[
            const Text(
              'Drivers in Location:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _driversByLocation.length,
                itemBuilder: (context, index) {
                  final driver = _driversByLocation[index];
                  return ListTile(
                    title: Text(driver.name),
                    subtitle: Text('ID: ${driver.id}'),
                    trailing: Text(driver.geohash),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Model Driver (dựa trên backend)
class Driver {
  final String id;
  final String name;
  final String status;

  Driver({required this.id, required this.name, required this.status});

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

// Model cho DriverByLocation
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
      id: json['id'].toString(),
      name: json['name'] ?? '',
      geohash: json['geohash'] ?? '',
    );
  }
}
