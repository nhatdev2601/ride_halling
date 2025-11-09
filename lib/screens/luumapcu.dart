// @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: _currentPosition,
//               zoom: 14,
//             ),
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             polylines: _polylines,
//             markers: _markers,
//             gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
//               Factory<OneSequenceGestureRecognizer>(
//                 () => EagerGestureRecognizer(),
//               ),
//             },
//             onMapCreated: (controller) {
//               _mapController = controller;
//             },
//           ),

//           SafeArea(
//             child: Container(
//               margin: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: AppTheme.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.menu, color: AppTheme.darkGrey),
//                       onPressed: () {},
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: AppTheme.primaryGreen,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppTheme.primaryGreen.withOpacity(0.3),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: const Text(
//                       'RideApp',
//                       style: TextStyle(
//                         color: AppTheme.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: AppTheme.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.person_outline,
//                         color: AppTheme.darkGrey,
//                       ),
//                       onPressed: () {},
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: AppTheme.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 12,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           _buildLocationField(
//                             controller: _pickupController,
//                             hint: 'Điểm đi',
//                             icon: Icons.location_on,
//                             onChanged: _handlePickupChange,
//                             suggestions: _pickupSuggestions,
//                             showSuggestions: _showPickupSuggestions,
//                             onSuggestionSelected: (suggestion) {
//                               _pickupController.text =
//                                   suggestion['description'] ?? '';
//                               _handlePickupChange(
//                                 suggestion['description'] ?? '',
//                               );
//                               FocusScope.of(context).unfocus();
//                               setState(() {
//                                 _showPickupSuggestions = false;
//                               });
//                             },
//                           ),
//                           Divider(
//                             height: 1,
//                             color: AppTheme.lightGrey,
//                             indent: 16,
//                             endIndent: 16,
//                           ),
//                           _buildLocationField(
//                             controller: _destinationController,
//                             hint: 'Điểm đến',
//                             icon: Icons.location_on,
//                             onChanged: _handleDestinationChange,
//                             suggestions: _destinationSuggestions,
//                             showSuggestions: _showDestinationSuggestions,
//                             onSuggestionSelected: (suggestion) {
//                               setState(() {
//                                 _destinationSuggestions.clear();
//                                 _showDestinationSuggestions = false;
//                               });
//                               _destinationController.text =
//                                   suggestion['description'] ?? '';
//                               _destinationLocation =
//                                   suggestion['description'] ?? '';
//                               _updateRoute();
//                               FocusScope.of(context).unfocus();
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (_isLoadingRoute)
//                       Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: SizedBox(
//                           height: 20,
//                           child: LinearProgressIndicator(
//                             backgroundColor: AppTheme.lightGrey,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               AppTheme.primaryGreen,
//                             ),
//                           ),
//                         ),
//                       ),
//                     if (_distance.isNotEmpty && _duration.isNotEmpty)
//                       Container(
//                         margin: const EdgeInsets.all(16),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: AppTheme.primaryGreen.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(
//                             color: AppTheme.primaryGreen,
//                             width: 1,
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: [
//                             Column(
//                               children: [
//                                 const Icon(
//                                   Icons.straighten,
//                                   color: AppTheme.primaryGreen,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   _distance,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: AppTheme.primaryGreen,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Column(
//                               children: [
//                                 const Icon(
//                                   Icons.schedule,
//                                   color: AppTheme.primaryGreen,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   _duration,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: AppTheme.primaryGreen,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             Column(
//                               children: [
//                                 const Icon(
//                                   Icons.local_taxi,
//                                   color: AppTheme.primaryGreen,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   _fare,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: AppTheme.primaryGreen,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           Positioned(
//             bottom: 20,
//             left: 16,
//             right: 16,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 if (_showVehicleOptions && _distance.isNotEmpty)
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: AppTheme.primaryGreen.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: AppTheme.primaryGreen,
//                         width: 2,
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Chọn loại xe',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _buildVehicleOption(
//                           'bike',
//                           '🏍️ Xe máy',
//                           _calculateFareByType('bike'),
//                         ),
//                         _buildVehicleOption(
//                           'car',
//                           '🚗 Ô tô',
//                           _calculateFareByType('car'),
//                         ),
//                         _buildVehicleOption(
//                           'delivery',
//                           '🚚 Giao hàng',
//                           _calculateFareByType('delivery'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _showVehicleOptions = !_showVehicleOptions;
//                     });
//                   },
//                   child: BottomBookButton(onPressed: _onBookRide),
//                 ),
//               ],
//             ),
//           ),

//           Positioned(
//             right: 16,
//             bottom: 100,
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

//   Widget _buildLocationField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     required Function(String) onChanged,
//     required List<Map<String, dynamic>> suggestions,
//     required bool showSuggestions,
//     required Function(Map<String, dynamic>) onSuggestionSelected,
//   }) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//           child: TextField(
//             controller: controller,
//             onChanged: onChanged,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(color: AppTheme.lightGrey),
//               prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//         if (showSuggestions)
//           Container(
//             constraints: BoxConstraints(maxHeight: 200),
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: suggestions.length > 5 ? 5 : suggestions.length,
//               itemBuilder: (context, index) {
//                 final suggestion = suggestions[index];
//                 return ListTile(
//                   dense: true,
//                   title: Text(
//                     suggestion['description'] ?? '',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(fontSize: 14),
//                   ),
//                   onTap: () => onSuggestionSelected(suggestion),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildVehicleOption(String type, String label, double fare) {
//     bool isSelected = _selectedVehicleType == type;
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedVehicleType = type;
//         });
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isSelected ? AppTheme.primaryGreen : AppTheme.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: AppTheme.primaryGreen,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: isSelected ? AppTheme.white : AppTheme.darkGrey,
//               ),
//             ),
//             Text(
//               '${fare.toStringAsFixed(0)} VND',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//                 color: isSelected ? AppTheme.white : AppTheme.primaryGreen,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
