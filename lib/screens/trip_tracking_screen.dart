import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'trip_rating_screen.dart';

class TripTrackingScreen extends StatefulWidget {
  final Trip trip;

  const TripTrackingScreen({super.key, required this.trip});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  TripStatus _currentStatus = TripStatus.requesting;
  Driver? _assignedDriver;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _simulateTrip();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeMap() {
    // Map initialization removed - using placeholder instead
  }

  void _simulateTrip() async {
    // Simulate trip progression
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _currentStatus = TripStatus.driverFound;
        //Thông tin tài xế
        _assignedDriver = Driver(
          id: '1',
          name: 'nhat',
          photo: 'assets/images/driver_avatar.png',
          phoneNumber: '0901234567',
          vehiclePlate: '30A-12345',
          vehicleModel: 'Honda Wave',
          vehicleColor: 'Đỏ',
          rating: 4.8,
          totalTrips: 1250,
        );
      });
    }

    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      setState(() {
        _currentStatus = TripStatus.driverArriving;
      });
    }

    await Future.delayed(const Duration(seconds: 8));
    if (mounted) {
      setState(() {
        _currentStatus = TripStatus.inProgress;
      });
    }

    await Future.delayed(const Duration(seconds: 15));
    if (mounted) {
      setState(() {
        _currentStatus = TripStatus.completed;
      });
      _showTripCompleted();
    }
  }

  void _showTripCompleted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TripRatingScreen(trip: widget.trip),
      ),
    );
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case TripStatus.requesting:
        return 'Đang tìm tài xế...';
      case TripStatus.driverFound:
        return 'Đã tìm thấy tài xế';
      case TripStatus.driverArriving:
        return 'Tài xế đang đến';
      case TripStatus.inProgress:
        return 'Đang trong chuyến đi';
      case TripStatus.completed:
        return 'Hoàn thành chuyến đi';
      case TripStatus.cancelled:
        return 'Chuyến đi đã bị hủy';
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case TripStatus.requesting:
        return AppTheme.warning;
      case TripStatus.driverFound:
      case TripStatus.driverArriving:
        return AppTheme.info;
      case TripStatus.inProgress:
        return AppTheme.primaryGreen;
      case TripStatus.completed:
        return AppTheme.success;
      case TripStatus.cancelled:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map placeholder
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
                    Icons.route,
                    size: 80,
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tracking Map',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.grey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              _getStatusText(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: _assignedDriver != null ? () {} : null,
                          ),
                        ],
                      ),

                      if (_currentStatus == TripStatus.requesting)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(
                                backgroundColor: AppTheme.lightGrey,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen.withOpacity(
                                    0.5 + (_pulseController.value * 0.5),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // Driver info and trip details
                if (_assignedDriver != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Driver info
                        Row(
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
                                    _assignedDriver!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                                        '${_assignedDriver!.rating} (${_assignedDriver!.totalTrips} chuyến)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_assignedDriver!.vehicleModel} - ${_assignedDriver!.vehiclePlate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.phone,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.message,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Trip details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
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
                                      widget.trip.pickupAddress,
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
                                      widget.trip.destinationAddress,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tổng cước: ${widget.trip.fare.toInt()}đ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  Text(
                                    widget.trip.paymentMethod ==
                                            PaymentMethod.cash
                                        ? 'Tiền mặt'
                                        : 'Thanh toán online',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (_currentStatus != TripStatus.completed)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                // Cancel trip


                                
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.error,
                              ),
                              child: const Text(
                                'Hủy chuyến đi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
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
