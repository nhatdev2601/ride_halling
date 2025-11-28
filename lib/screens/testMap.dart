// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import '../theme/app_theme.dart';
// import '../widgets/location_input.dart';
// import '../widgets/bottom_book_button.dart';
// import 'vehicle_selection_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String _pickupLocation = '';
//   String _destinationLocation = '';

//   GoogleMapController? _mapController;
//   LatLng _currentPosition = const LatLng(10.762622, 106.660172); // default HCM

//   //  Lấy vị trí hiện tại
//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Kiểm tra GPS bật chưa
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Vui lòng bật GPS để lấy vị trí.'),
//           backgroundColor: AppTheme.error,
//         ),
//       );
//       return;
//     }

//     // Xin quyền truy cập
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return;
//     }

//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Ứng dụng bị từ chối quyền truy cập vị trí.'),
//           backgroundColor: AppTheme.error,
//         ),
//       );
//       return;
//     }

//     // Lấy vị trí hiện tại
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     setState(() {
//       _currentPosition = LatLng(position.latitude, position.longitude);
//     });

//     // Di chuyển camera đến vị trí mới
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(_currentPosition, 15),
//     );
//   }

//   void _onBookRide() {
//     if (_pickupLocation.isNotEmpty && _destinationLocation.isNotEmpty) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => VehicleSelectionScreen(
//             pickupLocation: _pickupLocation,
//             destinationLocation: _destinationLocation,
//           ),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Vui lòng nhập điểm đi và điểm đến'),
//           backgroundColor: AppTheme.error,
//         ),
//       );
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation(); // tự động lấy vị trí khi vào app
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // 🗺️ Google Map thật
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: _currentPosition,
//               zoom: 14,
//             ),
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             onMapCreated: (controller) => _mapController = controller,
//           ),

//           // Overlay với UI
//           SafeArea(
//             child: Column(
//               children: [
//                 // Header với logo
//                 Container(
//                   margin: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 48,
//                         height: 48,
//                         decoration: BoxDecoration(
//                           color: AppTheme.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: IconButton(
//                           icon: const Icon(
//                             Icons.menu,
//                             color: AppTheme.darkGrey,
//                           ),
//                           onPressed: () {},
//                         ),
//                       ),
//                       const Spacer(),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryGreen,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: AppTheme.primaryGreen.withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: const Text(
//                           'RideApp',
//                           style: TextStyle(
//                             color: AppTheme.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const Spacer(),
//                       Container(
//                         width: 48,
//                         height: 48,
//                         decoration: BoxDecoration(
//                           color: AppTheme.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: IconButton(
//                           icon: const Icon(
//                             Icons.person_outline,
//                             color: AppTheme.darkGrey,
//                           ),
//                           onPressed: () {},
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Ô nhập địa chỉ
//                 LocationInput(
//                   onPickupChanged: (value) => _pickupLocation = value,
//                   onDestinationChanged: (value) => _destinationLocation = value,
//                 ),

//                 const Spacer(),

//                 // Nút đặt xe
//                 BottomBookButton(onPressed: _onBookRide),
//               ],
//             ),
//           ),

//           // 🧭 Nút định vị hiện tại
//           Positioned(
//             right: 16,
//             bottom: 180,
//             child: FloatingActionButton(
//               mini: true,
//               backgroundColor: AppTheme.white,
//               onPressed: _getCurrentLocation,
//               child: const Icon(
//                 Icons.my_location,
//                 color: AppTheme.primaryGreen,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
