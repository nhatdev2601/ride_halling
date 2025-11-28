// admin_home.dart - Cập nhật để thêm tab Analytics
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_management.dart';
import 'driver_management.dart';
import 'ride_monitoring.dart';
import 'analytics_page.dart'; // Import trang mới

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  // Các trang con - Thêm Analytics
  static const List<Widget> _pages = <Widget>[
    UserManagementPage(),
    DriverManagementPage(),
    RideMonitoringPage(),
    AnalyticsPage(), // Trang mới
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.drive_eta), label: 'Tài xế'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Chuyến xe',
          ),
          BottomNavigationBarItem(
            // Tab mới
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
