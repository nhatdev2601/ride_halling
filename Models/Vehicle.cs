using Cassandra.Mapping.Attributes;

namespace api_ride.Models
{
    [Table("vehicles")]
    public class Vehicle
    {
        [PartitionKey]
        [Column("vehicle_id")]
        public Guid VehicleId { get; set; }

        [Column("driver_id")]
        public Guid DriverId { get; set; }

        [Column("vehicle_type")]
        public string VehicleType { get; set; } = string.Empty; // bike, car, business

        [Column("brand")]
        public string Brand { get; set; } = string.Empty;

        [Column("model")]
        public string Model { get; set; } = string.Empty;

        [Column("color")]
        public string Color { get; set; } = string.Empty;

        [Column("license_plate")]
        public string LicensePlate { get; set; } = string.Empty;

        [Column("status")]
        public string Status { get; set; } = "active"; // active, inactive, maintenance

        [Column("created_at")]
        public DateTime CreatedAt { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; }
    }
}