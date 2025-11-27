namespace api_ride.Models.DTOs
{
    public class UserUpdateRequest
    {
        public string? FullName { get; set; }
        public string? Phone { get; set; }
        public string? Status { get; set; } // Admin có thể khóa/kích hoạt user
    }

    public class DriverStatusUpdateRequest
    {
        public string OnlineStatus { get; set; } = string.Empty; // online, offline
        public bool IsAvailable { get; set; } // true/false
    }
}
