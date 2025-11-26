using Cassandra;
using api_ride.Models;
using api_ride.Models.DTOs;
using api_ride.Services;

namespace api_ride.Repositories
{
    public interface IRideRepository
    {
        Task<string> CreateRideAsync(CreateRideRequest request, string passengerId, CalculateFareResponse fareInfo);
        Task<Ride?> GetRideByIdAsync(string rideId);
        Task<bool> UpdateRideStatusAsync(string rideId, string status, string? driverId = null);
        Task<List<RideHistoryDto>> GetRidesByPassengerAsync(string passengerId, int limit = 20);
        Task<List<Ride>> GetRidesByDriverAsync(string driverId, int limit = 20);
        Task<List<Ride>> GetActiveRidesAsync();
        Task<bool> UpdateRideAsync(Ride ride);
        Task<bool> CancelRideAsync(string rideId, string reason);
    }

    public class RideRepository : IRideRepository
    {
        private readonly ICassandraService _cassandraService;

        public RideRepository(ICassandraService cassandraService)
        {
            _cassandraService = cassandraService;
        }

        // T?o ride 
        public async Task<string> CreateRideAsync(CreateRideRequest request, string passengerId, CalculateFareResponse fareInfo)
        {
            var rideId = Guid.NewGuid();
            var now = DateTime.UtcNow;
            decimal SafeDecimal(double value)
            {
                // Làm tròn 2 số thập phân để tránh lỗi "scale > 28"
                // Nếu là VNĐ thì làm tròn 0 luôn cũng được: Math.Round((decimal)value, 0)
                return Math.Round((decimal)value, 2);
            }
            var ride = new Ride
            {
                RideId = rideId,
                PassengerId = Guid.Parse(passengerId),
                PickupLocationLat = request.PickupLocation.Latitude,
                PickupLocationLng = request.PickupLocation.Longitude,
                PickupAddress = request.PickupLocation.Address,
                DropoffLocationLat = request.DestinationLocation.Latitude,
                DropoffLocationLng = request.DestinationLocation.Longitude,
                DropoffAddress = request.DestinationLocation.Address,
                VehicleType = request.VehicleType,
                Status = "requesting",
                EstimatedDistance = SafeDecimal(fareInfo.Distance),

                // Duration thường là int, giữ nguyên
                EstimatedDuration = fareInfo.EstimatedDuration,

                // Tiền bạc là decimal, dùng SafeDecimal trực tiếp (KHÔNG được ép kiểu thủ công)
                BaseFare = SafeDecimal(fareInfo.BaseFare),
                DistanceFare = SafeDecimal(fareInfo.DistanceFare),
                TimeFare = SafeDecimal(fareInfo.TimeFare),
                SurgeFare = SafeDecimal(fareInfo.SurgeFare),
                Discount = SafeDecimal(fareInfo.Discount),
                TotalFare = SafeDecimal(fareInfo.TotalFare),
                PaymentMethod = request.PaymentMethod,
                PaymentStatus = "pending",
                PromoCode = string.IsNullOrEmpty(request.PromoCode) ? null : request.PromoCode,
                CreatedAt = now
            };

            var success = await _cassandraService.CreateRideAsync(ride);
            return success ? rideId.ToString() : throw new InvalidOperationException("Failed to create ride");
        }

        // L?y thông tin ride
        public async Task<Ride?> GetRideByIdAsync(string rideId)
        {
            return await _cassandraService.GetRideByIdAsync(Guid.Parse(rideId));
        }
        public async Task<bool> CancelRideAsync(string rideId, string reason)
        {
            if (!Guid.TryParse(rideId, out var rideGuid))
            {
                return false;
            }

            // Gọi xuống Service để chạy cái Batch khổng lồ kia
            return await _cassandraService.CancelRideAsync(rideGuid, reason);
        }
        // C?p nh?t status
        public async Task<bool> UpdateRideStatusAsync(string rideId, string status, string? driverId = null)
        {
            var ride = await GetRideByIdAsync(rideId);
            if (ride == null) return false;

            ride.Status = status;

            if (!string.IsNullOrEmpty(driverId))
            {
                ride.DriverId = Guid.Parse(driverId);
                ride.AcceptedAt = DateTime.UtcNow;
            }

            return await _cassandraService.UpdateRideAsync(ride);
        }

        public async Task<List<RideHistoryDto>> GetRidesByPassengerAsync(string passengerId, int limit = 20)
        {
            return await _cassandraService.GetRidesByPassengerAsync(Guid.Parse(passengerId), limit);
        }

        public async Task<List<Ride>> GetRidesByDriverAsync(string driverId, int limit = 20)
        {
            return await _cassandraService.GetRidesByDriverAsync(Guid.Parse(driverId), limit);
        }

        public async Task<List<Ride>> GetActiveRidesAsync()
        {
            return await _cassandraService.GetActiveRidesAsync();
        }

        public async Task<bool> UpdateRideAsync(Ride ride)
        {
            return await _cassandraService.UpdateRideAsync(ride);
        }
    }
}