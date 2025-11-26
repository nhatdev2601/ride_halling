namespace api_ride.Models.DTOs
{
    public class RideHistoryDto
    {
        public Guid RideId { get; set; }
        public DateTime CreatedAt { get; set; }
        public string PickupAddress { get; set; }
        public string DropoffAddress { get; set; }
        public decimal TotalFare { get; set; }
        public string Status { get; set; }
        public string VehicleType { get; set; }
        public string PaymentMethod { get; set; } // Có thể null nếu bảng phụ không lưu
    }
}
