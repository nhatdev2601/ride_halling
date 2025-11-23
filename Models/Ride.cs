using Cassandra.Mapping.Attributes;

namespace api_ride.Models
{
    [Table("rides")]
    public class Ride
    {
        [PartitionKey]
        [Column("ride_id")]
        public Guid RideId { get; set; }

        [Column("passenger_id")]
        public Guid PassengerId { get; set; }

        [Column("driver_id")]
        public Guid? DriverId { get; set; }

        [Column("status")]
        public string Status { get; set; } = string.Empty; // requesting, accepted, arrived, in_progress, completed, cancelled

        [Column("pickup_location_lat")]
        public double PickupLocationLat { get; set; }

        [Column("pickup_location_lng")]
        public double PickupLocationLng { get; set; }

        [Column("pickup_address")]
        public string PickupAddress { get; set; } = string.Empty;

        [Column("dropoff_location_lat")]
        public double DropoffLocationLat { get; set; }

        [Column("dropoff_location_lng")]
        public double DropoffLocationLng { get; set; }

        [Column("dropoff_address")]
        public string DropoffAddress { get; set; } = string.Empty;

        [Column("vehicle_type")]
        public string VehicleType { get; set; } = string.Empty;

        [Column("estimated_distance")]
        public double EstimatedDistance { get; set; }

        [Column("actual_distance")]
        public double? ActualDistance { get; set; }

        [Column("estimated_duration")]
        public int EstimatedDuration { get; set; }

        [Column("actual_duration")]
        public int? ActualDuration { get; set; }

        [Column("base_fare")]
        public decimal BaseFare { get; set; }

        [Column("distance_fare")]
        public decimal DistanceFare { get; set; }

        [Column("time_fare")]
        public decimal TimeFare { get; set; }

        [Column("surge_fare")]
        public decimal SurgeFare { get; set; }

        [Column("discount")]
        public decimal Discount { get; set; }

        [Column("total_fare")]
        public decimal TotalFare { get; set; }

        [Column("payment_method")]
        public string PaymentMethod { get; set; } = string.Empty;

        [Column("payment_status")]
        public string PaymentStatus { get; set; } = "pending"; // pending, completed, failed

        [Column("promo_code")]
        public string? PromoCode { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("accepted_at")]
        public DateTime? AcceptedAt { get; set; }

        [Column("started_at")]
        public DateTime? StartedAt { get; set; }

        [Column("completed_at")]
        public DateTime? CompletedAt { get; set; }

        [Column("cancelled_at")]
        public DateTime? CancelledAt { get; set; }

        [Column("cancellation_reason")]
        public string? CancellationReason { get; set; }

        [Column("driver_rating")]
        public int? DriverRating { get; set; }

        [Column("passenger_rating")]
        public int? PassengerRating { get; set; }

        [Column("notes")]
        public string? Notes { get; set; }
    }
}