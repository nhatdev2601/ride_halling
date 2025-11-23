class CalculateFareRequest {
  final LocationDto pickupLocation;
  final LocationDto destinationLocation;
  final double distance;
  final String vehicleType;

  CalculateFareRequest({
    required this.pickupLocation,
    required this.destinationLocation,
    required this.distance,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() => {
    'pickupLocation': pickupLocation.toJson(),
    'destinationLocation': destinationLocation.toJson(),
    'distance': distance,
    'vehicleType': vehicleType,
  };
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
    latitude: json['latitude']?.toDouble() ?? 0.0,
    longitude: json['longitude']?.toDouble() ?? 0.0,
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
      rideId: json['rideId'] ?? '',
      distance: json['distance']?.toDouble() ?? 0.0,
      estimatedDuration: json['estimatedDuration'] ?? 0,
      baseFare: json['baseFare']?.toDouble() ?? 0.0,
      distanceFare: json['distanceFare']?.toDouble() ?? 0.0,
      timeFare: json['timeFare']?.toDouble() ?? 0.0,
      surgeFare: json['surgeFare']?.toDouble() ?? 0.0,
      discount: json['discount']?.toDouble() ?? 0.0,
      totalFare: json['totalFare']?.toDouble() ?? 0.0,
      availableVehicles:
          (json['availableVehicles'] as List?)
              ?.map((e) => VehicleOption.fromJson(e))
              .toList() ??
          [],
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
      baseFare: json['baseFare']?.toDouble() ?? 0.0,
      totalFare: json['totalFare']?.toDouble() ?? 0.0,
      estimatedArrival: json['estimatedArrival'] ?? 0,
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
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? '',
      totalFare: json['totalFare']?.toDouble() ?? 0.0,
      estimatedArrival: json['estimatedArrival'] ?? 0,
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
  final VehicleInfo vehicle;
  final LocationDto currentLocation;

  DriverInfo({
    required this.driverId,
    required this.fullName,
    required this.phoneNumber,
    required this.rating,
    required this.vehicle,
    required this.currentLocation,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      driverId: json['driverId'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
      vehicle: VehicleInfo.fromJson(json['vehicle'] ?? {}),
      currentLocation: LocationDto.fromJson(json['currentLocation'] ?? {}),
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
      vehicleType: json['vehicleType'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
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
  });

  factory RideDetail.fromJson(Map<String, dynamic> json) {
    return RideDetail(
      rideId: json['rideId'] ?? '',
      passengerId: json['passengerId'] ?? '',
      driverId: json['driverId'],
      status: json['status'] ?? '',
      pickupLocationLat: json['pickupLocationLat']?.toDouble() ?? 0.0,
      pickupLocationLng: json['pickupLocationLng']?.toDouble() ?? 0.0,
      pickupAddress: json['pickupAddress'] ?? '',
      dropoffLocationLat: json['dropoffLocationLat']?.toDouble() ?? 0.0,
      dropoffLocationLng: json['dropoffLocationLng']?.toDouble() ?? 0.0,
      dropoffAddress: json['dropoffAddress'] ?? '',
      totalFare: json['totalFare']?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
