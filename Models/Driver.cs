using Cassandra.Mapping.Attributes;

namespace api_ride.Models
{
    [Table("drivers")]
    public class Driver
    {
        [PartitionKey]
        [Column("driver_id")]
        public Guid DriverId { get; set; }

        [Column("user_id")]
        public Guid UserId { get; set; }

        [Column("license_number")]
        public string LicenseNumber { get; set; } = string.Empty;

        [Column("license_expiry")]
        public DateTime LicenseExpiry { get; set; }

        [Column("vehicle_id")]
        public Guid VehicleId { get; set; }

        [Column("current_location_lat")]
        public double CurrentLocationLat { get; set; }

        [Column("current_location_lng")]
        public double CurrentLocationLng { get; set; }

        [Column("is_available")]
        public bool IsAvailable { get; set; }

        [Column("online_status")]
        public string OnlineStatus { get; set; } = "offline"; // online, offline, busy

        [Column("rating")]
        public double Rating { get; set; }

        [Column("total_earnings")]
        public decimal TotalEarnings { get; set; }

        [Column("completed_trips")]
        public int CompletedTrips { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }
    }

    [Table("drivers_by_location")]
    public class DriverByLocation
    {
        [PartitionKey]
        [Column("geohash")]
        public string Geohash { get; set; } = string.Empty;

        [ClusteringKey]
        [Column("driver_id")]
        public Guid DriverId { get; set; }

        [Column("latitude")]
        public double Latitude { get; set; }

        [Column("longitude")]
        public double Longitude { get; set; }

        [Column("is_available")]
        public bool IsAvailable { get; set; }

        [Column("rating")]
        public double Rating { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }
    }
}