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
        Task<List<Ride>> GetRidesByPassengerAsync(string passengerId, int limit = 20);
        Task<List<Ride>> GetRidesByDriverAsync(string driverId, int limit = 20);
        Task<List<Ride>> GetActiveRidesAsync();
        Task<bool> UpdateRideAsync(Ride ride);
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
                EstimatedDistance = fareInfo.Distance,
                EstimatedDuration = fareInfo.EstimatedDuration,
                BaseFare = (decimal)fareInfo.BaseFare,
                DistanceFare = (decimal)fareInfo.DistanceFare,
                TimeFare = (decimal)fareInfo.TimeFare,
                SurgeFare = (decimal)fareInfo.SurgeFare,
                Discount = (decimal)fareInfo.Discount,
                TotalFare = (decimal)fareInfo.TotalFare,
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

        public async Task<List<Ride>> GetRidesByPassengerAsync(string passengerId, int limit = 20)
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