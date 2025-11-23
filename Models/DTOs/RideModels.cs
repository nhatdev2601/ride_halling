using System.ComponentModel.DataAnnotations;

namespace api_ride.Models.DTOs
{
    // DTO nh?n t? Flutter
    public class CalculateFareRequest
    {
        public Location PickupLocation { get; set; } = new Location();
        public Location DestinationLocation { get; set; } = new Location();
        public double Distance { get; set; } // km
        public string VehicleType { get; set; } = string.Empty; // "bike", "car", "business"
    }

    public class Location
    {
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string Address { get; set; } = string.Empty;
    }

    // Response tr? v? Flutter
    public class CalculateFareResponse
    {
        public string RideId { get; set; } = string.Empty;
        public double Distance { get; set; }
        public int EstimatedDuration { get; set; } // minutes
        public double BaseFare { get; set; }
        public double DistanceFare { get; set; }
        public double TimeFare { get; set; }
        public double SurgeFare { get; set; }
        public double Discount { get; set; }
        public double TotalFare { get; set; }
        public List<VehicleOption> AvailableVehicles { get; set; } = new List<VehicleOption>();
    }

    public class VehicleOption
    {
        public string VehicleType { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public double BaseFare { get; set; }
        public double TotalFare { get; set; }
        public int EstimatedArrival { get; set; } // minutes
        public string IconUrl { get; set; } = string.Empty;
    }

    // DTO ?? t?o ride
    public class CreateRideRequest
    {
        public Location PickupLocation { get; set; } = new Location();
        public Location DestinationLocation { get; set; } = new Location();
        public string VehicleType { get; set; } = string.Empty;
        public double Distance { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        public string PromoCode { get; set; } = string.Empty;
    }

    // Response sau khi t?o ride
    public class CreateRideResponse
    {
        public string RideId { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public double TotalFare { get; set; }
        public int EstimatedArrival { get; set; }
        public DriverInfo? AssignedDriver { get; set; }
    }

    public class DriverInfo
    {
        public string DriverId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public double Rating { get; set; }
        public VehicleInfo? Vehicle { get; set; }
        public Location? CurrentLocation { get; set; }
        public int EstimatedArrival { get; set; }
    }

    public class VehicleInfo
    {
        public string VehicleType { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public string Model { get; set; } = string.Empty;
        public string Color { get; set; } = string.Empty;
        public string LicensePlate { get; set; } = string.Empty;
    }
}