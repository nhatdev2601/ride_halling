import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/location_input.dart';
import '../widgets/bottom_book_button.dart';
import 'vehicle_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _pickupLocation = '';
  String _destinationLocation = '';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập điểm đi và điểm đến'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background map placeholder
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.1),
                  AppTheme.primaryGreen.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 100,
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bản đồ sẽ hiển thị ở đây',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.grey.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cần cấu hình Google Maps API Key',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay với các thành phần UI
          SafeArea(
            child: Column(
              children: [
                // Header với logo và menu
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

                // Ô nhập địa chỉ
                LocationInput(
                  onPickupChanged: (value) => _pickupLocation = value,
                  onDestinationChanged: (value) => _destinationLocation = value,
                ),

                const Spacer(),

                // Nút đặt xe
                BottomBookButton(onPressed: _onBookRide),
              ],
            ),
          ),

          // Nút vị trí hiện tại
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng định vị cần Google Maps API'),
                    backgroundColor: AppTheme.info,
                  ),
                );
              },
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
