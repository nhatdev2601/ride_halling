using api_ride.Models.DTOs;
using api_ride.Models;

namespace api_ride.Services
{
    public interface IDriverService
    {
        Task<DriverInfo?> FindNearestDriverAsync(double latitude, double longitude, string vehicleType);
        Task<List<DriverInfo>> GetAvailableDriversAsync(double latitude, double longitude, double radiusKm = 5);
        Task<bool> UpdateDriverLocationAsync(string driverId, double latitude, double longitude);
        Task<bool> SetDriverAvailabilityAsync(string driverId, bool isAvailable);
    }

    public class DriverService : IDriverService
    {
        private readonly ICassandraService _cassandraService;
        private readonly ILogger<DriverService> _logger;
        
        public DriverService(ICassandraService cassandraService, ILogger<DriverService> logger)
        {
            _cassandraService = cassandraService;
            _logger = logger;
        }

        public async Task<DriverInfo?> FindNearestDriverAsync(double latitude, double longitude, string vehicleType)
        {
            try
            {
                _logger.LogInformation($" Bắt đầu tìm xe quanh: {latitude}, {longitude} (Loại: {vehicleType})");
                // 1. Tạo Geohash xung quanh
                var geohashes = GenerateGeohashesAroundLocation(latitude, longitude);

                // List chứa ứng viên sơ bộ (chỉ mới check vị trí + distance)
                var candidates = new List<(DriverByLocation driverLoc, double distance)>();

                // 2. Quét Geohash để lấy ứng viên trong 5km
                foreach (var geohash in geohashes)
                {
                    var driversInArea = await _cassandraService.GetDriversByLocationAsync(geohash);
                    if (driversInArea.Any())
                    {
                        _logger.LogInformation($"📍 Tìm thấy {driversInArea.Count} tài xế trong ô {geohash}");
                    }
                    // Lọc sơ bộ: Phải IsAvailable trong bảng location
                    foreach (var d in driversInArea.Where(x => x.IsAvailable))
                    {
                        double dist = CalculateDistance(latitude, longitude, d.Latitude, d.Longitude);
                        _logger.LogInformation($"📏 Tài xế {d.DriverId} cách khách: {dist} km");
                        // Chốt chặn 5km
                        if (dist <= 5.0)
                        {
                            candidates.Add((d, dist));
                        }
                    }
                }

                // 3. Sắp xếp: Thằng nào gần nhất check trước
                var sortedCandidates = candidates.OrderBy(x => x.distance).ToList();

                // 4. Duyệt qua danh sách để tìm người phù hợp nhất (Online + Active)
                foreach (var candidate in sortedCandidates)
                {
                    // A. Lấy thông tin chi tiết Driver
                    var driverInfo = await _cassandraService.GetDriverByIdAsync(candidate.driverLoc.DriverId);

                    // 👉 CHECK KỸ: Phải Online, Phải Available, Không bị khoá
                    if (driverInfo == null) continue;
                    if (!driverInfo.IsAvailable) continue;
                    if (driverInfo.OnlineStatus != "online") continue;

                    // B. Lấy thông tin Xe (Vehicle)
                    var vehicle = await _cassandraService.GetVehicleByIdAsync(driverInfo.VehicleId);

                    // 👉 CHECK KỸ: Xe phải Active, Đúng loại xe khách đặt
                    if (vehicle == null) continue;
                    if (vehicle.Status != "active") continue;
                    if (vehicle.VehicleType.ToLower() != vehicleType.ToLower()) continue;

                    // C. Lấy thông tin User (để hiện tên)
                    var user = await _cassandraService.GetUserByIdAsync(driverInfo.UserId);
                    if (user == null || user.Status != "active") continue;

                    // ✅ TÌM THẤY RỒI! TRẢ VỀ NGAY
                    return new DriverInfo
                    {
                        DriverId = driverInfo.DriverId.ToString(),
                        FullName = user.FullName,
                        PhoneNumber = user.Phone,
                        Rating = driverInfo.Rating,
                        EstimatedArrival = CalculateEstimatedArrival(candidate.distance, vehicleType),
                        Vehicle = new VehicleInfo
                        {
                            VehicleType = vehicle.VehicleType,
                            Brand = vehicle.Brand,
                            Model = vehicle.Model,
                            Color = vehicle.Color,
                            LicensePlate = vehicle.LicensePlate
                        },
                        CurrentLocation = new Location
                        {
                            Latitude = candidate.driverLoc.Latitude,
                            Longitude = candidate.driverLoc.Longitude
                        }
                    };
                }

                // Duyệt hết list mà không ai thoả mãn
                _logger.LogWarning("Found {Count} drivers in range but none matched criteria (Online/Active/Type)", sortedCandidates.Count);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error finding nearest driver");
                return null;
            }
        }

        public async Task<List<DriverInfo>> GetAvailableDriversAsync(double latitude, double longitude, double radiusKm = 5)
        {
            try
            {
                var geohashes = GenerateGeohashesAroundLocation(latitude, longitude);
                var availableDrivers = new List<DriverInfo>();

                foreach (var geohash in geohashes)
                {
                    var driversInArea = await _cassandraService.GetDriversByLocationAsync(geohash);
                    
                    foreach (var driverLocation in driversInArea.Where(d => d.IsAvailable))
                    {
                        // Calculate distance first to avoid unnecessary DB calls
                        var distance = CalculateDistance(latitude, longitude, driverLocation.Latitude, driverLocation.Longitude);
                        if (distance > radiusKm) continue;

                        // Get full driver info
                        var driverInfo = await _cassandraService.GetDriverByIdAsync(driverLocation.DriverId);
                        if (driverInfo == null || !driverInfo.IsAvailable || driverInfo.OnlineStatus != "online")
                            continue;

                        // Get vehicle info
                        var vehicle = await _cassandraService.GetVehicleByIdAsync(driverInfo.VehicleId);
                        if (vehicle == null || vehicle.Status != "active")
                            continue;

                        // Get user info
                        var user = await _cassandraService.GetUserByIdAsync(driverInfo.UserId);
                        if (user == null) continue;

                        var estimatedArrival = CalculateEstimatedArrival(distance, vehicle.VehicleType);

                        availableDrivers.Add(new DriverInfo
                        {
                            DriverId = driverInfo.DriverId.ToString(),
                            FullName = user.FullName,
                            PhoneNumber = user.Phone,
                            Rating = driverInfo.Rating,
                            EstimatedArrival = estimatedArrival,
                            Vehicle = new VehicleInfo
                            {
                                VehicleType = vehicle.VehicleType,
                                Brand = vehicle.Brand,
                                Model = vehicle.Model,
                                Color = vehicle.Color,
                                LicensePlate = vehicle.LicensePlate
                            },
                            CurrentLocation = new Location
                            {
                                Latitude = driverLocation.Latitude,
                                Longitude = driverLocation.Longitude,
                                Address = ""
                            }
                        });
                    }
                }

                return availableDrivers
                    .OrderBy(d => CalculateDistance(latitude, longitude, d.CurrentLocation?.Latitude ?? 0, d.CurrentLocation?.Longitude ?? 0))
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting available drivers");
                return new List<DriverInfo>();
            }
        }

        public async Task<bool> UpdateDriverLocationAsync(string driverId, double latitude, double longitude)
        {
            try
            {
                if (!Guid.TryParse(driverId, out var driverGuid))
                    return false;

                // Generate geohash for the new location
                var geohash = NGeoHash.GeoHash.Encode(latitude, longitude, 6);

                return await _cassandraService.UpdateDriverLocationAsync(driverGuid, latitude, longitude, geohash);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driver location");
                return false;
            }
        }

        public async Task<bool> SetDriverAvailabilityAsync(string driverId, bool isAvailable)
        {
            try
            {
                if (!Guid.TryParse(driverId, out var driverGuid))
                    return false;

                return await _cassandraService.SetDriverAvailabilityAsync(driverGuid, isAvailable);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting driver availability");
                return false;
            }
        }

        // Helper methods
        private List<string> GenerateGeohashesAroundLocation(double latitude, double longitude)
        {
            var geohashes = new List<string>();
            
            // Start with high precision and gradually reduce
            for (int precision = 6; precision >= 4; precision--)
            {
                var centerHash = NGeoHash.GeoHash.Encode(latitude, longitude, precision);
                geohashes.Add(centerHash);
                
                // Add neighboring geohashes at this precision level
                var neighbors = NGeoHash.GeoHash.Neighbors(centerHash);
                if (neighbors != null)
                {
                    geohashes.AddRange(neighbors);
                }
            }
            
            return geohashes.Distinct().ToList();
        }

        private int CalculateEstimatedArrival(double distance, string vehicleType)
        {
            // Average speeds by vehicle type (km/h)
            var speed = vehicleType.ToLower() switch
            {
                "bike" => 25,
                "car" => 30,
                "business" => 25,
                _ => 25
            };
            
            var timeInHours = distance / speed;
            var timeInMinutes = (int)Math.Ceiling(timeInHours * 60);
            
            return Math.Max(timeInMinutes, 2); // Minimum 2 minutes
        }

        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371; // Earth's radius in kilometers
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);
            
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                   Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                   Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c; // Distance in kilometers
        }

        private double ToRadians(double degrees)
        {
            return degrees * Math.PI / 180;
        }
    }
}