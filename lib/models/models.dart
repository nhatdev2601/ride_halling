class Driver {
  final String id;
  final String name;
  final String photo;
  final String phoneNumber;
  final String vehiclePlate;
  final String vehicleModel;
  final String vehicleColor;
  final double rating;
  final int totalTrips;

  Driver({
    required this.id,
    required this.name,
    required this.photo,
    required this.phoneNumber,
    required this.vehiclePlate,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.rating,
    required this.totalTrips,
  });
}

class VehicleType {
  final String id;
  final String name;
  final String iconPath;
  final String description;
  final double baseFare;
  final double pricePerKm;
  final int estimatedTime;
  final int capacity;

  VehicleType({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.description,
    required this.baseFare,
    required this.pricePerKm,
    required this.estimatedTime,
    required this.capacity,
  });
}

class Trip {
  final String id;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final VehicleType vehicleType;
  final Driver? driver;
  final double fare;
  final DateTime createdAt;
  final TripStatus status;
  final PaymentMethod paymentMethod;
  final double? driverRating;
  final String? feedback;

  Trip({
    required this.id,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.vehicleType,
    this.driver,
    required this.fare,
    required this.createdAt,
    required this.status,
    required this.paymentMethod,
    this.driverRating,
    this.feedback,
  });
}

enum TripStatus {
  requesting,
  driverFound,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

enum PaymentMethod { cash, wallet, creditCard, debitCard }

class Location {
  final double latitude;
  final double longitude;
  final String address;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}
