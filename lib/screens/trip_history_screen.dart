import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final List<Trip> _tripHistory = [
    Trip(
      id: '1',
      pickupAddress: '123 Đường ABC, Quận 1, TP.HCM',
      destinationAddress: '456 Đường XYZ, Quận 3, TP.HCM',
      pickupLat: 21.0285,
      pickupLng: 105.8542,
      destinationLat: 21.0245,
      destinationLng: 105.8412,
      vehicleType: VehicleType(
        id: '1',
        name: 'RideBike',
        iconPath: 'motorcycle',
        description: 'Tiết kiệm, đi nhanh trong thành phố',
        baseFare: 15000,
        pricePerKm: 3500,
        estimatedTime: 12,
        capacity: 1,
      ),
      driver: Driver(
        id: '1',
        name: 'NMhat',
        photo: 'assets/images/driver_avatar.png',
        phoneNumber: '0901234567',
        vehiclePlate: '30A-12345',
        vehicleModel: 'Honda Wave',
        vehicleColor: 'Đỏ',
        rating: 4.8,
        totalTrips: 1250,
      ),
      fare: 32500,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: TripStatus.completed,
      paymentMethod: PaymentMethod.cash,
      driverRating: 5.0,
      feedback: 'Tài xế lịch sự, đúng giờ',
    ),
    Trip(
      id: '2',
      pickupAddress: '789 Đường DEF, Quận 7, TP.HCM',
      destinationAddress: '321 Đường GHI, Quận 2, TP.HCM',
      pickupLat: 21.0285,
      pickupLng: 105.8542,
      destinationLat: 21.0245,
      destinationLng: 105.8412,
      vehicleType: VehicleType(
        id: '2',
        name: 'RideCar',
        iconPath: 'car',
        description: 'Thoải mái cho 4 người',
        baseFare: 25000,
        pricePerKm: 8500,
        estimatedTime: 15,
        capacity: 4,
      ),
      driver: Driver(
        id: '2',
        name: 'Trần Thị Bình',
        photo: 'assets/images/driver_avatar2.png',
        phoneNumber: '0907654321',
        vehiclePlate: '29B-67890',
        vehicleModel: 'Toyota Vios',
        vehicleColor: 'Trắng',
        rating: 4.9,
        totalTrips: 890,
      ),
      fare: 67500,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: TripStatus.completed,
      paymentMethod: PaymentMethod.wallet,
      driverRating: 4.0,
    ),
    Trip(
      id: '3',
      pickupAddress: 'Sân bay Tân Sơn Nhất',
      destinationAddress: '555 Đường JKL, Quận 1, TP.HCM',
      pickupLat: 21.0285,
      pickupLng: 105.8542,
      destinationLat: 21.0245,
      destinationLng: 105.8412,
      vehicleType: VehicleType(
        id: '3',
        name: 'RidePremium',
        iconPath: 'premium_car',
        description: 'Xe sang, dịch vụ VIP',
        baseFare: 45000,
        pricePerKm: 15000,
        estimatedTime: 10,
        capacity: 4,
      ),
      driver: Driver(
        id: '3',
        name: 'Lê Minh Châu',
        photo: 'assets/images/driver_avatar3.png',
        phoneNumber: '0909876543',
        vehiclePlate: '51F-11111',
        vehicleModel: 'Mercedes C200',
        vehicleColor: 'Đen',
        rating: 4.95,
        totalTrips: 567,
      ),
      fare: 120000,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      status: TripStatus.completed,
      paymentMethod: PaymentMethod.creditCard,
      driverRating: 5.0,
      feedback: 'Xe sang, tài xế chuyên nghiệp',
    ),
  ];

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

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.wallet:
        return 'Ví điện tử';
      case PaymentMethod.creditCard:
        return 'Thẻ tín dụng';
      case PaymentMethod.debitCard:
        return 'Thẻ ghi nợ';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
          'Lịch sử chuyến đi',
          style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.black),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tripHistory.length,
        itemBuilder: (context, index) {
          final trip = _tripHistory[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showTripDetails(trip);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with date and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(trip.createdAt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Hoàn thành',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Trip route
                      Row(
                        children: [
                          // Vehicle icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getVehicleIcon(trip.vehicleType.iconPath),
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Route info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      color: AppTheme.primaryGreen,
                                      size: 8,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        trip.pickupAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.square,
                                      color: AppTheme.error,
                                      size: 8,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        trip.destinationAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Trip details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.vehicleType.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getPaymentMethodText(trip.paymentMethod),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${trip.fare.toInt()}đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.black,
                                ),
                              ),
                              if (trip.driverRating != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppTheme.warning,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      trip.driverRating!.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTripDetails(Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Chi tiết chuyến đi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
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
                                  trip.pickupAddress,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.square,
                                color: AppTheme.error,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  trip.destinationAddress,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Driver info
                    if (trip.driver != null) ...[
                      const Text(
                        'Thông tin tài xế',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.lightGrey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.lightGrey,
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.driver!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${trip.driver!.vehicleModel} - ${trip.driver!.vehiclePlate}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: AppTheme.warning,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trip.driver!.rating} (${trip.driver!.totalTrips} chuyến)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // Payment details
                    const Text(
                      'Chi tiết thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGrey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Loại xe:'),
                              Text(
                                trip.vehicleType.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Phương thức thanh toán:'),
                              Text(
                                _getPaymentMethodText(trip.paymentMethod),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cược:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${trip.fare.toInt()}đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (trip.feedback != null) ...[
                      const SizedBox(height: 24),

                      const Text(
                        'Đánh giá của bạn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (trip.driverRating != null)
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      size: 20,
                                      color: index < trip.driverRating!
                                          ? AppTheme.warning
                                          : AppTheme.grey.withOpacity(0.3),
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    trip.driverRating!.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            if (trip.feedback!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                trip.feedback!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
