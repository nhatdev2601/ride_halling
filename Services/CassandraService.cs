using Cassandra;
using Cassandra.Mapping;
using api_ride.Models;
using CassandraSession = Cassandra.ISession;

namespace api_ride.Services
{
    public interface ICassandraService
    {
        Task<User?> GetUserByIdAsync(Guid userId);
        Task<User?> GetUserByEmailAsync(string email);
        Task<bool> CreateUserAsync(User user);
        Task<bool> UpdateUserAsync(User user);
        Task<bool> CreateRefreshTokenAsync(RefreshToken refreshToken);
        Task<RefreshToken?> GetRefreshTokenAsync(string token);
        Task<bool> RevokeRefreshTokenAsync(string token);
        Task<bool> RevokeAllUserRefreshTokensAsync(Guid userId);
 

        // Ride operations
        Task<bool> CreateRideAsync(Ride ride);
        Task<Ride?> GetRideByIdAsync(Guid rideId);
        Task<bool> UpdateRideAsync(Ride ride);
        Task<List<Ride>> GetRidesByPassengerAsync(Guid passengerId, int limit = 20);
        Task<List<Ride>> GetRidesByDriverAsync(Guid driverId, int limit = 20);
        Task<List<Ride>> GetActiveRidesAsync();
        
        // Driver operations
        Task<Driver?> GetDriverByIdAsync(Guid driverId);
        Task<Driver?> GetDriverByUserIdAsync(Guid userId);
        Task<List<DriverByLocation>> GetDriversByLocationAsync(string geohash);
        Task<List<DriverByLocation>> GetDriversByLocationPrefixAsync(string geohashPrefix);
        Task<bool> UpdateDriverLocationAsync(Guid driverId, double latitude, double longitude, string geohash);
        Task<bool> SetDriverAvailabilityAsync(Guid driverId, bool isAvailable);
        
        // Vehicle operations
        Task<Vehicle?> GetVehicleByIdAsync(Guid vehicleId);
        Task<Vehicle?> GetVehicleByDriverIdAsync(Guid driverId);
        //query để giải lập tài xế
        Task ExecuteAsync(string query, object[] args);
    }

    public class CassandraService : ICassandraService, IDisposable
    {
        private readonly ICluster _cluster;
        private readonly CassandraSession _session;
        private readonly IMapper _mapper;
        private readonly ILogger<CassandraService> _logger;

       
        
        public CassandraService(IConfiguration configuration, ILogger<CassandraService> logger)
        {
            _logger = logger;

            var keyspace = configuration["Cassandra:Keyspace"] ?? "ride";
            var connectionString = configuration.GetConnectionString("Cassandra") ?? "127.0.0.1";
            var hosts = connectionString.Split(',');
            var port = configuration.GetValue<int>("Cassandra:Port", 9042);
            var username = configuration["Cassandra:Username"] ?? "cassandra";
            var password = configuration["Cassandra:Password"] ?? "cassandra";

            var builder = Cluster.Builder()
                .AddContactPoints(hosts)
                .WithPort(port)
                .WithCredentials(username, password);

            _cluster = builder.Build();
            _session = _cluster.Connect(keyspace);
            _mapper = new Mapper(_session);

            _logger.LogInformation("Connected to Cassandra successfully");
        }
        public async Task<User?> GetUserByIdAsync(Guid userId)
        {
            try
            {
                return await _mapper.FirstOrDefaultAsync<User>("SELECT * FROM users WHERE user_id = ?", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user by ID");
                return null;
            }
        }

        public async Task<User?> GetUserByEmailAsync(string email)
        {
            try
            {
                // Direct CQL without mapper to avoid any mapping issues
                var cql = "SELECT user_id, full_name, phone_number, email, password, user_type, status, created_at, updated_at FROM users WHERE email = ? ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(email));
                var row = result.FirstOrDefault();

                if (row == null) return null;

                return new User
                {
                    UserId = row.GetValue<Guid>("user_id"),
                    FullName = row.GetValue<string>("full_name") ?? "",
                    Phone = row.GetValue<string>("phone_number") ?? "",
                    Email = row.GetValue<string>("email") ?? "",
                    Password = row.GetValue<string>("password") ?? "",
                    Role = row.GetValue<string>("user_type") ?? "",
                    Status = row.GetValue<string>("status") ?? "active",
                    CreatedAt = row.GetValue<DateTime>("created_at"),
                    UpdatedAt = row.GetValue<DateTime>("updated_at")
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user by email: {Email}", email);
                return null;
            }
        }

        public async Task<bool> CreateUserAsync(User user)
        {
            try
            {
                if (user.UserId == Guid.Empty)
                    user.UserId = Guid.NewGuid();

                user.CreatedAt = DateTime.UtcNow;
                user.UpdatedAt = DateTime.UtcNow;

                // Direct CQL insert to avoid any mapping complexity
                var cql = "INSERT INTO users (user_id, full_name, phone_number, email, password, user_type, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    user.UserId,
                    user.FullName,
                    user.Phone,
                    user.Email,
                    user.Password,
                    user.Role,
                    user.Status,
                    user.CreatedAt,
                    user.UpdatedAt
                ));

                _logger.LogInformation("User created: {UserId}", user.UserId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                return false;
            }
        }

        public async Task<bool> UpdateUserAsync(User user)
        {
            try
            {
                user.UpdatedAt = DateTime.UtcNow;

                var cql = "UPDATE users SET full_name = ?, phone_number = ?, password = ?, user_type = ?, status = ?, updated_at = ? WHERE user_id = ?";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    user.FullName,
                    user.Phone,
                    user.Password,
                    user.Role,
                    user.Status,
                    user.UpdatedAt,
                    user.UserId
                ));

                _logger.LogInformation("User updated: {UserId}", user.UserId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user");
                return false;
            }
        }

        public async Task<bool> CreateRefreshTokenAsync(RefreshToken refreshToken)
        {
            try
            {
                var cql = "INSERT INTO refresh_tokens (\"token\", user_id, expires_at, created_at, is_revoked) VALUES (?, ?, ?, ?, ?)";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    refreshToken.Token,
                    refreshToken.UserId,
                    refreshToken.ExpiresAt,
                    refreshToken.CreatedAt,
                    refreshToken.IsRevoked
                ));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating refresh token");
                return false;
            }
        }

        public async Task<RefreshToken?> GetRefreshTokenAsync(string token)
        {
            try
            {
                var cql = "SELECT \"token\", user_id, expires_at, created_at, is_revoked FROM refresh_tokens WHERE \"token\" = ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(token));
                var row = result.FirstOrDefault();

                if (row == null) return null;

                return new RefreshToken
                {
                    Token = row.GetValue<string>("token") ?? "",
                    UserId = row.GetValue<Guid>("user_id"),
                    ExpiresAt = row.GetValue<DateTime>("expires_at"),
                    CreatedAt = row.GetValue<DateTime>("created_at"),
                    IsRevoked = row.GetValue<bool>("is_revoked")
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting refresh token");
                return null;
            }
        }

        public async Task<bool> RevokeRefreshTokenAsync(string token)
        {
            try
            {
                var cql = "UPDATE refresh_tokens SET is_revoked = ? WHERE \"token\" = ?";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(true, token));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking refresh token");
                return false;
            }
        }

        public async Task<bool> RevokeAllUserRefreshTokensAsync(Guid userId)
        {
            try
            {
                var cql = "UPDATE refresh_tokens SET is_revoked = ? WHERE user_id = ?";
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(true, userId));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking all user refresh tokens");
                return false;
            }
        }


        // Ride operations
        public async Task<bool> CreateRideAsync(Ride ride)
        {
            try
            {
                

                var cql = @"
                    INSERT INTO rides (
                        ride_id, passenger_id, driver_id, status, pickup_location_lat, pickup_location_lng,
                        pickup_address, dropoff_location_lat, dropoff_location_lng, dropoff_address,
                        vehicle_type, estimated_distance, estimated_duration, base_fare, distance_fare,
                        time_fare, surge_fare, discount, total_fare, payment_method, payment_status,
                        promo_code, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ";
                
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    ride.RideId, ride.PassengerId, ride.DriverId, ride.Status,
                    ride.PickupLocationLat, ride.PickupLocationLng, ride.PickupAddress,
                    ride.DropoffLocationLat, ride.DropoffLocationLng, ride.DropoffAddress,
                    ride.VehicleType, ride.EstimatedDistance, ride.EstimatedDuration,
                    ride.BaseFare, ride.DistanceFare, ride.TimeFare, ride.SurgeFare,
                    ride.Discount, ride.TotalFare, ride.PaymentMethod, ride.PaymentStatus,
                    ride.PromoCode, ride.CreatedAt
                ));
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating ride");
                return false;
            }
        }

        public async Task<Ride?> GetRideByIdAsync(Guid rideId)
        {
            try
            {
               

                var cql = "SELECT * FROM rides WHERE ride_id = ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(rideId));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return MapRowToRide(row);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting ride by ID");
                return null;
            }
        }

        public async Task<bool> UpdateRideAsync(Ride ride)
        {
            try
            {
                
              

                var cql = @"
                    UPDATE rides SET 
                        driver_id = ?, status = ?, accepted_at = ?, started_at = ?, completed_at = ?,
                        cancelled_at = ?, cancellation_reason = ?, actual_distance = ?, actual_duration = ?,
                        driver_rating = ?, passenger_rating = ?, notes = ?
                    WHERE ride_id = ?
                ";
                
                var statement = await _session.PrepareAsync(cql);
                await _session.ExecuteAsync(statement.Bind(
                    ride.DriverId, ride.Status, ride.AcceptedAt, ride.StartedAt, ride.CompletedAt,
                    ride.CancelledAt, ride.CancellationReason, ride.ActualDistance, ride.ActualDuration,
                    ride.DriverRating, ride.PassengerRating, ride.Notes, ride.RideId
                ));
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating ride");
                return false;
            }
        }

        public async Task<List<Ride>> GetRidesByPassengerAsync(Guid passengerId, int limit = 20)
        {
            try
            {
                

                var cql = "SELECT * FROM rides WHERE passenger_id = ? LIMIT ? ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(passengerId, limit));
                
                return result.Select(MapRowToRide).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rides by passenger");
                return new List<Ride>();
            }
        }

        public async Task<List<Ride>> GetRidesByDriverAsync(Guid driverId, int limit = 20)
        {
            try
            {
                

                var cql = "SELECT * FROM rides WHERE driver_id = ? LIMIT ? ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(driverId, limit));
                
                return result.Select(MapRowToRide).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rides by driver");
                return new List<Ride>();
            }
        }

        public async Task<List<Ride>> GetActiveRidesAsync()
        {
            try
            {
              

                var cql = "SELECT * FROM rides WHERE status IN ('requesting', 'accepted', 'arrived', 'in_progress') ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind());
                
                return result.Select(MapRowToRide).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting active rides");
                return new List<Ride>();
            }
        }

        // Driver operations
        public async Task<Driver?> GetDriverByIdAsync(Guid driverId)
        {
            try
            {
              

                var cql = @"SELECT driver_id, user_id, license_number, license_expiry, vehicle_id, 
                           current_location_lat, current_location_lng, is_available, online_status, 
                           rating, total_earnings, completed_trips, created_at, updated_at 
                           FROM drivers WHERE driver_id = ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(driverId));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return MapRowToDriver(row);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting driver by ID");
                return null;
            }
        }

        public async Task<Driver?> GetDriverByUserIdAsync(Guid userId)
        {
            try
            {
              

                var cql = @"SELECT driver_id, user_id, license_number, license_expiry, vehicle_id, 
                           current_location_lat, current_location_lng, is_available, online_status, 
                           rating, total_earnings, completed_trips, created_at, updated_at 
                           FROM drivers WHERE user_id = ? ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(userId));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return MapRowToDriver(row);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting driver by user ID");
                return null;
            }
        }

        public async Task<List<DriverByLocation>> GetDriversByLocationAsync(string geohash)
        {
            try
            {


                var cql = @"SELECT geohash, driver_id, latitude, longitude, is_available, rating, updated_at 
                    FROM drivers_by_location 
                    WHERE geohash = ?";

                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(geohash));

                return result.Select(MapRowToDriverByLocation).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting drivers by location");
                return new List<DriverByLocation>();
            }
        }

        public async Task<List<DriverByLocation>> GetDriversByLocationPrefixAsync(string geohashPrefix)
        {
            try
            {
             

                var drivers = new List<DriverByLocation>();
                
                // Generate possible geohash values for the prefix
                var possibleHashes = GenerateGeohashesForPrefix(geohashPrefix);
                
                foreach (var hash in possibleHashes)
                {
                    var hashDrivers = await GetDriversByLocationAsync(hash);
                    drivers.AddRange(hashDrivers);
                }
                
                return drivers;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting drivers by location prefix");
                return new List<DriverByLocation>();
            }
        }

        public async Task<bool> UpdateDriverLocationAsync(Guid driverId, double latitude, double longitude, string geohash)
        {
            try
            {
             

                // Update driver's current location
                var updateDriverCql = @"UPDATE drivers SET current_location_lat = ?, current_location_lng = ?, updated_at = ? WHERE driver_id = ?";
                var updateDriverStatement = await _session.PrepareAsync(updateDriverCql);
                await _session.ExecuteAsync(updateDriverStatement.Bind(latitude, longitude, DateTime.UtcNow, driverId));
                
                // Update driver location index
                var updateLocationCql = @"UPDATE drivers_by_location SET latitude = ?, longitude = ?, updated_at = ? WHERE geohash = ? AND driver_id = ?";
                var updateLocationStatement = await _session.PrepareAsync(updateLocationCql);
                await _session.ExecuteAsync(updateLocationStatement.Bind(latitude, longitude, DateTime.UtcNow, geohash, driverId));
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driver location");
                return false;
            }
        }

        public async Task<bool> SetDriverAvailabilityAsync(Guid driverId, bool isAvailable)
        {
            try
            {
             

                // Get current driver info to get geohash
                var driver = await GetDriverByIdAsync(driverId);
                if (driver == null) return false;
                
                // Calculate geohash from current location
                var geohash = NGeoHash.GeoHash.Encode(driver.CurrentLocationLat, driver.CurrentLocationLng, 6);
                
                // Update driver availability
                var updateDriverCql = @"UPDATE drivers SET is_available = ?, updated_at = ? WHERE driver_id = ?";
                var updateDriverStatement = await _session.PrepareAsync(updateDriverCql);
                await _session.ExecuteAsync(updateDriverStatement.Bind(isAvailable, DateTime.UtcNow, driverId));
                
                // Update location index
                var updateLocationCql = @"UPDATE drivers_by_location SET is_available = ?, updated_at = ? WHERE geohash = ? AND driver_id = ?";
                var updateLocationStatement = await _session.PrepareAsync(updateLocationCql);
                await _session.ExecuteAsync(updateLocationStatement.Bind(isAvailable, DateTime.UtcNow, geohash, driverId));
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting driver availability");
                return false;
            }
        }

        // Vehicle operations
        public async Task<Vehicle?> GetVehicleByIdAsync(Guid vehicleId)
        {
            try
            {
              

                var cql = @"SELECT vehicle_id, driver_id, vehicle_type, brand, model, color, license_plate, status, created_at, updated_at 
                           FROM vehicles WHERE vehicle_id = ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(vehicleId));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return MapRowToVehicle(row);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting vehicle by ID");
                return null;
            }
        }

        public async Task<Vehicle?> GetVehicleByDriverIdAsync(Guid driverId)
        {
            try
            {
               

                var cql = @"SELECT vehicle_id, driver_id, vehicle_type, brand, model, color, license_plate, status, created_at, updated_at 
                           FROM vehicles WHERE driver_id = ? ALLOW FILTERING";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(driverId));
                var row = result.FirstOrDefault();
                
                if (row == null) return null;

                return MapRowToVehicle(row);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting vehicle by driver ID");
                return null;
            }
        }

        private Ride MapRowToRide(Row row)
        {
            return new Ride
            {
                RideId = row.GetValue<Guid>("ride_id"),
                PassengerId = row.GetValue<Guid>("passenger_id"),
                DriverId = row.GetValue<Guid?>("driver_id"),
                Status = row.GetValue<string>("status") ?? "",
                PickupLocationLat = row.GetValue<double>("pickup_location_lat"),
                PickupLocationLng = row.GetValue<double>("pickup_location_lng"),
                PickupAddress = row.GetValue<string>("pickup_address") ?? "",
                DropoffLocationLat = row.GetValue<double>("dropoff_location_lat"),
                DropoffLocationLng = row.GetValue<double>("dropoff_location_lng"),
                DropoffAddress = row.GetValue<string>("dropoff_address") ?? "",
                VehicleType = row.GetValue<string>("vehicle_type") ?? "",
                EstimatedDistance = row.GetValue<double>("estimated_distance"),
                ActualDistance = row.GetValue<double?>("actual_distance"),
                EstimatedDuration = row.GetValue<int>("estimated_duration"),
                ActualDuration = row.GetValue<int?>("actual_duration"),
                BaseFare = row.GetValue<decimal>("base_fare"),
                DistanceFare = row.GetValue<decimal>("distance_fare"),
                TimeFare = row.GetValue<decimal>("time_fare"),
                SurgeFare = row.GetValue<decimal>("surge_fare"),
                Discount = row.GetValue<decimal>("discount"),
                TotalFare = row.GetValue<decimal>("total_fare"),
                PaymentMethod = row.GetValue<string>("payment_method") ?? "",
                PaymentStatus = row.GetValue<string>("payment_status") ?? "",
                PromoCode = row.GetValue<string>("promo_code"),
                CreatedAt = row.GetValue<DateTime>("created_at"),
                AcceptedAt = row.GetValue<DateTime?>("accepted_at"),
                StartedAt = row.GetValue<DateTime?>("started_at"),
                CompletedAt = row.GetValue<DateTime?>("completed_at"),
                CancelledAt = row.GetValue<DateTime?>("cancelled_at"),
                CancellationReason = row.GetValue<string>("cancellation_reason"),
                DriverRating = row.GetValue<int?>("driver_rating"),
                PassengerRating = row.GetValue<int?>("passenger_rating"),
                Notes = row.GetValue<string>("notes")
            };
        }

        private Driver MapRowToDriver(Row row)
        {
            var expiryDate = row.GetValue<Cassandra.LocalDate>("license_expiry");
            return new Driver
            {
                DriverId = row.GetValue<Guid>("driver_id"),
                UserId = row.GetValue<Guid>("user_id"),
                LicenseNumber = row.GetValue<string>("license_number") ?? "",
                LicenseExpiry = expiryDate != null
            ? new DateTime(expiryDate.Year, expiryDate.Month, expiryDate.Day)
            : DateTime.MinValue,
                VehicleId = row.GetValue<Guid>("vehicle_id"),
                CurrentLocationLat = row.GetValue<double>("current_location_lat"),
                CurrentLocationLng = row.GetValue<double>("current_location_lng"),
                IsAvailable = row.GetValue<bool>("is_available"),
                OnlineStatus = row.GetValue<string>("online_status") ?? "offline",
                Rating = (double)row.GetValue<decimal>("rating"),
                TotalEarnings = row.GetValue<decimal>("total_earnings"),
                CompletedTrips = row.GetValue<int>("completed_trips"),
                CreatedAt = row.GetValue<DateTime?>("created_at") ?? DateTime.MinValue,
                UpdatedAt = row.GetValue<DateTime?>("updated_at") ?? DateTime.MinValue
            };
        }

        private DriverByLocation MapRowToDriverByLocation(Row row)
        {
            return new DriverByLocation
            {
                Geohash = row.GetValue<string>("geohash") ?? "",
                DriverId = row.GetValue<Guid>("driver_id"),
                Latitude = row.GetValue<double>("latitude"),
                Longitude = row.GetValue<double>("longitude"),
                IsAvailable = row.GetValue<bool>("is_available"),
                Rating = (double)row.GetValue<decimal>("rating"),
                UpdatedAt = row.GetValue<DateTime?>("updated_at") ?? DateTime.MinValue
            };
        }

        private Vehicle MapRowToVehicle(Row row)
        {
            return new Vehicle
            {
                VehicleId = row.GetValue<Guid>("vehicle_id"),
                DriverId = row.GetValue<Guid>("driver_id"),
                VehicleType = row.GetValue<string>("vehicle_type") ?? "",
                Brand = row.GetValue<string>("brand") ?? "",
                Model = row.GetValue<string>("model") ?? "",
                Color = row.GetValue<string>("color") ?? "",
                LicensePlate = row.GetValue<string>("license_plate") ?? "",
                Status = row.GetValue<string>("status") ?? "",
                CreatedAt = row.GetValue<DateTime?>("created_at") ?? DateTime.MinValue,
                UpdatedAt = row.GetValue<DateTime?>("updated_at") ?? DateTime.MinValue
            };
        }

        private List<string> GenerateGeohashesForPrefix(string prefix)
        {
            // For a more comprehensive search, we'll generate all possible geohashes
            // that start with the given prefix at the next precision level
            var geohashes = new List<string>();
            var base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
            
            foreach (char c in base32)
            {
                geohashes.Add(prefix + c);
            }
            
            return geohashes;
        }
        // 👇 THÊM HÀM NÀY VÀO ĐỂ SỬA LỖI
        public async Task ExecuteAsync(string query, object[] args)
        {
            try
            {
                // 1. Chuẩn bị câu lệnh (Prepare)
                var preparedStatement = await _session.PrepareAsync(query);

                // 2. Gán tham số (Bind)
                var boundStatement = preparedStatement.Bind(args);

                // 3. Thực thi
                await _session.ExecuteAsync(boundStatement);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing raw CQL query: {Query}", query);
                throw; // Ném lỗi ra để Controller biết mà báo về Client
            }
        }
        public void Dispose()
        {
            _session?.Dispose();
            _cluster?.Dispose();
        }
    }
}