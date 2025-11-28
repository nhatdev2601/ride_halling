import 'dart:convert';

class CalculateFareRequest {
  final LocationDto pickupLocation;
  final LocationDto destinationLocation;
  final double distance;
  final String vehicleType;
  final String? promoCode;
  CalculateFareRequest({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.distance,
    required this.vehicleType,
    this.promoCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'pickupLocation': pickupLocation.toJson(),
      'destinationLocation': destinationLocation.toJson(),
      'distance': distance,
      'vehicleType': vehicleType,
    };

    //  Chỉ thêm promoCode nếu nó không rỗng
    if (promoCode != null && promoCode!.isNotEmpty) {
      map['promoCode'] = promoCode!;
    }

    return map;
  }
}

class RideHistoryItem {
  final String rideId;
  final DateTime createdAt;
  final String pickupAddress;
  final String dropoffAddress;
  final double totalFare;
  final String status;
  final String vehicleType;
  final String? paymentMethod;

  RideHistoryItem({
    required this.rideId,
    required this.createdAt,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.totalFare,
    required this.status,
    required this.vehicleType,
    this.paymentMethod,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    return RideHistoryItem(
      //  Check cả 2 kiểu key cho chắc ăn
      rideId: json['rideId'] ?? json['ride_id'] ?? '',
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      pickupAddress: json['pickupAddress'] ?? json['pickup_address'] ?? '',
      dropoffAddress: json['dropoffAddress'] ?? json['dropoff_address'] ?? '',
      totalFare:
          double.tryParse(
            json['totalFare']?.toString() ??
                json['total_fare']?.toString() ??
                '0',
          ) ??
          0.0,
      status: json['status'] ?? 'unknown',
      vehicleType: json['vehicleType'] ?? json['vehicle_type'] ?? 'bike',
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
    );
  }
}

class LocationDto {
  final double latitude;
  final double longitude;
  final String address;

  LocationDto({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory LocationDto.fromJson(Map<String, dynamic> json) => LocationDto(
    latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
    longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
    address: json['address'] ?? '',
  );
}

class CalculateFareResponse {
  final String rideId;
  final double distance;
  final int estimatedDuration;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeFare;
  final double discount;
  final double totalFare;
  final List<VehicleOption> availableVehicles;

  CalculateFareResponse({
    required this.rideId,
    required this.distance,
    required this.estimatedDuration,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeFare,
    required this.discount,
    required this.totalFare,
    required this.availableVehicles,
  });

  factory CalculateFareResponse.fromJson(Map<String, dynamic> json) {
    return CalculateFareResponse(
      rideId: json['rideId'] ?? json['ride_id'] ?? '',
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
      estimatedDuration:
          int.tryParse(json['estimatedDuration']?.toString() ?? '0') ?? 0,
      baseFare: double.tryParse(json['baseFare']?.toString() ?? '0') ?? 0.0,
      distanceFare:
          double.tryParse(json['distanceFare']?.toString() ?? '0') ?? 0.0,
      timeFare: double.tryParse(json['timeFare']?.toString() ?? '0') ?? 0.0,
      surgeFare: double.tryParse(json['surgeFare']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      totalFare: double.tryParse(json['totalFare']?.toString() ?? '0') ?? 0.0,
      availableVehicles:
          (json['availableVehicles'] as List?)
              ?.map((e) => VehicleOption.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Ride {
  final String id;
  late final String status;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String passengerName; // Từ API
  final double distance; // km
  final double earnings; // VNĐ

  Ride({
    required this.id,
    required this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.passengerName,
    required this.distance,
    required this.earnings,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['rideId'] ?? json['id'] ?? '',
      status: json['status'] ?? '',
      pickupAddress: json['pickupAddress'],
      dropoffAddress: json['dropoffAddress'],
      pickupLat: (json['pickupLocationLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLocationLng'] as num?)?.toDouble(),
      passengerName: json['passengerName'] ?? 'Khách hàng',
      distance: (json['estimatedDistance'] as num?)?.toDouble() ?? 0.0,
      earnings: (json['totalFare'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VehicleOption {
  final String vehicleType;
  final String displayName;
  final double baseFare;
  final double totalFare;
  final int estimatedArrival;
  final String iconUrl;

  VehicleOption({
    required this.vehicleType,
    required this.displayName,
    required this.baseFare,
    required this.totalFare,
    required this.estimatedArrival,
    required this.iconUrl,
  });

  factory VehicleOption.fromJson(Map<String, dynamic> json) {
    return VehicleOption(
      vehicleType: json['vehicleType'] ?? '',
      displayName: json['displayName'] ?? '',
      baseFare: double.tryParse(json['baseFare']?.toString() ?? '0') ?? 0.0,
      totalFare: double.tryParse(json['totalFare']?.toString() ?? '0') ?? 0.0,
      estimatedArrival:
          int.tryParse(json['estimatedArrival']?.toString() ?? '0') ?? 0,
      iconUrl: json['iconUrl'] ?? '',
    );
  }
}

class CreateRideRequest {
  final LocationDto pickupLocation;
  final LocationDto destinationLocation;
  final String vehicleType;
  final String paymentMethod;
  final String? promoCode;
  final double distance;

  CreateRideRequest({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.vehicleType,
    required this.paymentMethod,
    this.promoCode,
    required this.distance,
  });

  Map<String, dynamic> toJson() => {
    'pickupLocation': pickupLocation.toJson(),
    'destinationLocation': destinationLocation.toJson(),
    'vehicleType': vehicleType,
    'paymentMethod': paymentMethod,
    if (promoCode != null) 'promoCode': promoCode,
    'distance': distance,
  };
}

class CreateRideResponse {
  final String rideId;
  final String status;
  final double totalFare;
  final int estimatedArrival;
  final DriverInfo? assignedDriver;

  CreateRideResponse({
    required this.rideId,
    required this.status,
    required this.totalFare,
    required this.estimatedArrival,
    this.assignedDriver,
  });

  factory CreateRideResponse.fromJson(Map<String, dynamic> json) {
    return CreateRideResponse(
      rideId: json['rideId'] ?? json['ride_id'] ?? '',
      status: json['status'] ?? '',
      totalFare: double.tryParse(json['totalFare']?.toString() ?? '0') ?? 0.0,
      estimatedArrival:
          int.tryParse(json['estimatedArrival']?.toString() ?? '0') ?? 0,
      assignedDriver: json['assignedDriver'] != null
          ? DriverInfo.fromJson(json['assignedDriver'])
          : null,
    );
  }
}

class DriverInfo {
  final String driverId;
  final String fullName;
  final String phoneNumber;
  final double rating;
  final VehicleInfo? vehicle; // Xe có thể null nếu chưa load
  final LocationDto? currentLocation;

  DriverInfo({
    required this.driverId,
    required this.fullName,
    required this.phoneNumber,
    required this.rating,
    this.vehicle,
    this.currentLocation,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      //  Map cả 2 kiểu key cho chắc
      driverId: json['driverId'] ?? json['driver_id'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? 'Tài xế',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,

      vehicle: (json['vehicle'] != null)
          ? VehicleInfo.fromJson(json['vehicle'])
          : null,

      currentLocation:
          (json['currentLocation'] != null || json['current_location'] != null)
          ? LocationDto.fromJson(
              json['currentLocation'] ?? json['current_location'],
            )
          : null,
    );
  }
}

class VehicleInfo {
  final String vehicleType;
  final String brand;
  final String model;
  final String color;
  final String licensePlate;

  VehicleInfo({
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.color,
    required this.licensePlate,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      vehicleType: json['vehicleType'] ?? json['vehicle_type'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      licensePlate: json['licensePlate'] ?? json['license_plate'] ?? '',
    );
  }
}

class RideDetail {
  final String rideId;
  final String passengerId;
  final String? driverId;
  final String status;
  final double pickupLocationLat;
  final double pickupLocationLng;
  final String pickupAddress;
  final double dropoffLocationLat;
  final double dropoffLocationLng;
  final String dropoffAddress;
  final double totalFare;
  final String paymentMethod;
  final DateTime createdAt;
  final DriverInfo? driverInfo; //  Quan trọng: Cái này để hiển thị tài xế

  RideDetail({
    required this.rideId,
    required this.passengerId,
    this.driverId,
    required this.status,
    required this.pickupLocationLat,
    required this.pickupLocationLng,
    required this.pickupAddress,
    required this.dropoffLocationLat,
    required this.dropoffLocationLng,
    required this.dropoffAddress,
    required this.totalFare,
    required this.paymentMethod,
    required this.createdAt,
    this.driverInfo,
  });

  factory RideDetail.fromJson(Map<String, dynamic> json) {
    return RideDetail(
      //  Fix lại toàn bộ key cho khớp với Backend (snake_case)
      rideId: json['rideId'] ?? json['ride_id'] ?? '',
      passengerId: json['passengerId'] ?? json['passenger_id'] ?? '',
      driverId: json['driverId'] ?? json['driver_id'],
      status: json['status'] ?? 'pending',

      pickupLocationLat:
          double.tryParse(
            json['pickupLocationLat']?.toString() ??
                json['pickup_location_lat']?.toString() ??
                '0',
          ) ??
          0.0,
      pickupLocationLng:
          double.tryParse(
            json['pickupLocationLng']?.toString() ??
                json['pickup_location_lng']?.toString() ??
                '0',
          ) ??
          0.0,
      pickupAddress: json['pickupAddress'] ?? json['pickup_address'] ?? '',

      dropoffLocationLat:
          double.tryParse(
            json['dropoffLocationLat']?.toString() ??
                json['dropoff_location_lat']?.toString() ??
                '0',
          ) ??
          0.0,
      dropoffLocationLng:
          double.tryParse(
            json['dropoffLocationLng']?.toString() ??
                json['dropoff_location_lng']?.toString() ??
                '0',
          ) ??
          0.0,
      dropoffAddress: json['dropoffAddress'] ?? json['dropoff_address'] ?? '',

      totalFare:
          double.tryParse(
            json['totalFare']?.toString() ??
                json['total_fare']?.toString() ??
                '0',
          ) ??
          0.0,
      paymentMethod: json['paymentMethod'] ?? json['payment_method'] ?? 'cash',

      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),

      //  CÁI MÀY BỊ THIẾU LÚC NÃY ĐÂY:
      driverInfo: (json['driverInfo'] != null || json['driver_info'] != null)
          ? DriverInfo.fromJson(json['driverInfo'] ?? json['driver_info'])
          : null,
    );
  }
}
