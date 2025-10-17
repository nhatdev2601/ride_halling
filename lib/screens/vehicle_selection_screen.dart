import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'trip_tracking_screen.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final String pickupLocation;
  final String destinationLocation;

  const VehicleSelectionScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  VehicleType? _selectedVehicle;
  PaymentMethod _selectedPayment = PaymentMethod.cash;

  final List<VehicleType> _vehicleTypes = [
    VehicleType(
      id: '1',
      name: 'RideBike',
      iconPath: 'motorcycle',
      description: 'Tiết kiệm, đi nhanh trong thành phố',
      baseFare: 15000,
      pricePerKm: 3500,
      estimatedTime: 12,
      capacity: 1,
    ),
    VehicleType(
      id: '2',
      name: 'RideCar',
      iconPath: 'car',
      description: 'Thoải mái cho 4 người',
      baseFare: 25000,
      pricePerKm: 8500,
      estimatedTime: 15,
      capacity: 4,
    ),
    VehicleType(
      id: '3',
      name: 'RidePremium',
      iconPath: 'premium_car',
      description: 'Xe sang, dịch vụ VIP',
      baseFare: 45000,
      pricePerKm: 15000,
      estimatedTime: 10,
      capacity: 4,
    ),
  ];

  double _calculateFare(VehicleType vehicle) {
    // Giả sử khoảng cách 5km
    const double distance = 5.0;
    return vehicle.baseFare + (vehicle.pricePerKm * distance);
  }

  IconData _getVehicleIcon(String iconPath) {
    switch (iconPath) {
      case 'motorcycle':
        return Icons.motorcycle;
      case 'car':
        return Icons.directions_car;
      case 'premium_car':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  void _bookRide() {
    if (_selectedVehicle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripTrackingScreen(
            trip: Trip(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              pickupAddress: widget.pickupLocation,
              destinationAddress: widget.destinationLocation,
              pickupLat: 21.0285,
              pickupLng: 105.8542,
              destinationLat: 21.0245,
              destinationLng: 105.8412,
              vehicleType: _selectedVehicle!,
              fare: _calculateFare(_selectedVehicle!),
              createdAt: DateTime.now(),
              status: TripStatus.requesting,
              paymentMethod: _selectedPayment,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn loại xe',
          style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thông tin chuyến đi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: AppTheme.primaryGreen,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.pickupLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.square, color: AppTheme.error, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.destinationLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Danh sách loại xe
          Expanded(
            child: Container(
              color: AppTheme.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicleTypes[index];
                  final fare = _calculateFare(vehicle);
                  final isSelected = _selectedVehicle?.id == vehicle.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedVehicle = vehicle;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.lightGrey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Icon xe
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryGreen.withOpacity(0.2)
                                      : AppTheme.lightGrey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getVehicleIcon(vehicle.iconPath),
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : AppTheme.grey,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Thông tin xe
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.primaryGreen
                                            : AppTheme.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vehicle.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${vehicle.estimatedTime} phút',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Giá cước
                              Text(
                                '${fare.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : AppTheme.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Phương thức thanh toán và nút đặt xe
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.white,
            child: Column(
              children: [
                // Phương thức thanh toán
                Row(
                  children: [
                    const Icon(Icons.payment, color: AppTheme.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Thanh toán:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<PaymentMethod>(
                      value: _selectedPayment,
                      underline: const SizedBox(),
                      onChanged: (value) {
                        if (value != null) {
                          ///// chuyển api thanh toán /tiền mặt
                          setState(() {
                            _selectedPayment = value;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: PaymentMethod.cash,
                          child: Text('Tiền mặt'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.wallet,
                          child: Text('Ví điện tử'),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.creditCard,
                          child: Text('Thẻ tín dụng'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nút đặt xe
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedVehicle != null ? _bookRide : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedVehicle != null
                          ? 'Đặt ${_selectedVehicle!.name}'
                          : 'Chọn loại xe',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
