using api_ride.Models;
using api_ride.Models.DTOs;
using Cassandra;
using Cassandra.Mapping;
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
        Task<List<RideHistoryDto>> GetRidesByPassengerAsync(Guid passengerId, int limit = 20);
        Task<List<Ride>> GetRidesByDriverAsync(Guid driverId, int limit = 20);
        Task<List<Ride>> GetActiveRidesAsync();
        // Trong ICassandraService
        Task<bool> CancelRideAsync(Guid rideId, string reason);
        // Driver operations
        Task<DriverInfo?> GetDriverInfoWithPhoneAsync(Guid rideId);
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
                // Bước 1: Tìm ID từ bảng phụ (Query cực nhanh vì email là Key)
                var idCql = "SELECT user_id FROM users_by_email WHERE email = ?";
                var idRow = (await _session.ExecuteAsync((await _session.PrepareAsync(idCql)).Bind(email))).FirstOrDefault();

                if (idRow == null) return null; // Không tìm thấy email

                // Bước 2: Lấy thông tin chi tiết từ bảng chính
                var userId = idRow.GetValue<Guid>("user_id");
                return await GetUserByIdAsync(userId);
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

                // 1. Chuẩn bị câu lệnh Insert cho bảng chính (users)
                var queryUsers = "INSERT INTO users (user_id, full_name, phone_number, email, password, user_type, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                var psUsers = await _session.PrepareAsync(queryUsers);
                var statementUsers = psUsers.Bind(
                    user.UserId, user.FullName, user.Phone, user.Email, user.Password,
                    user.Role, user.Status, user.CreatedAt, user.UpdatedAt
                );

                // 2. Chuẩn bị câu lệnh Insert cho bảng lookup Email (users_by_email)
                // Lưu ý: Chỉ lưu những thông tin cần thiết để hiển thị nhanh hoặc validate
                var queryEmail = "INSERT INTO users_by_email (email, user_id, full_name, phone_number, user_type, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)";
                var psEmail = await _session.PrepareAsync(queryEmail);
                var statementEmail = psEmail.Bind(
                    user.Email, user.UserId, user.FullName, user.Phone,
                    user.Role, user.Status, user.CreatedAt
                );

                // 3. Chuẩn bị câu lệnh Insert cho bảng lookup Phone (users_by_phone)
                var queryPhone = "INSERT INTO users_by_phone (phone_number, user_id, email, full_name, status, user_type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)";
                var psPhone = await _session.PrepareAsync(queryPhone);
                var statementPhone = psPhone.Bind(
                    user.Phone, user.UserId, user.Email, user.FullName,
                    user.Status, user.Role, user.CreatedAt
                );

                // 4. Gộp tất cả vào một BATCH
                var batch = new BatchStatement();
                batch.Add(statementUsers);
                batch.Add(statementEmail);
                batch.Add(statementPhone);

                // 5. Thực thi Batch (Chỉ 1 lần gọi network)
                await _session.ExecuteAsync(batch);

                _logger.LogInformation("User created fully in 3 tables: {UserId}", user.UserId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user in batch");
                return false;
            }
        }

        public async Task<bool> UpdateUserAsync(User user)
        {
            try
            {
                user.UpdatedAt = DateTime.UtcNow;

                // 1. Update bảng chính
                var cqlMain = "UPDATE users SET full_name = ?, password = ?, updated_at = ? WHERE user_id = ?";
                var stMain = (await _session.PrepareAsync(cqlMain)).Bind(user.FullName, user.Password, user.UpdatedAt, user.UserId);

                // 2. Update bảng users_by_email (Cần email cũ để làm key, tao giả sử user.Email không đổi)
                var cqlEmail = "UPDATE users_by_email SET full_name = ? WHERE email = ?";
                var stEmail = (await _session.PrepareAsync(cqlEmail)).Bind(user.FullName, user.Email);

                // 3. Update bảng users_by_phone
                var cqlPhone = "UPDATE users_by_phone SET full_name = ? WHERE phone_number = ?";
                var stPhone = (await _session.PrepareAsync(cqlPhone)).Bind(user.FullName, user.Phone);

                var batch = new BatchStatement();
                batch.Add(stMain);
                batch.Add(stEmail);
                batch.Add(stPhone);

                await _session.ExecuteAsync(batch);
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

        public async Task<bool> CreateRideAsync(Ride ride)
        {
            try
            {
                // 1. Insert vào bảng chính (rides)
                var cqlMain = @"
            INSERT INTO rides (
                ride_id, passenger_id, driver_id, status, pickup_location_lat, pickup_location_lng,
                pickup_address, dropoff_location_lat, dropoff_location_lng, dropoff_address,
                vehicle_type, estimated_distance, estimated_duration, base_fare, distance_fare,
                time_fare, surge_fare, discount, total_fare, payment_method, payment_status,
                promo_code, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

                var psMain = await _session.PrepareAsync(cqlMain);
                var stMain = psMain.Bind(
                    ride.RideId, ride.PassengerId, ride.DriverId, ride.Status,
                    ride.PickupLocationLat, ride.PickupLocationLng, ride.PickupAddress,
                    ride.DropoffLocationLat, ride.DropoffLocationLng, ride.DropoffAddress,
                    ride.VehicleType, ride.EstimatedDistance, ride.EstimatedDuration,
                    ride.BaseFare, ride.DistanceFare, ride.TimeFare, ride.SurgeFare,
                    ride.Discount, ride.TotalFare, ride.PaymentMethod, ride.PaymentStatus,
                    ride.PromoCode, ride.CreatedAt
                );

                // 2. Insert vào bảng rides_by_passenger (ĐỂ USER XEM ĐƯỢC LỊCH SỬ)
                // Lưu ý: Bảng này chỉ cần vài cột quan trọng để hiển thị list
                var cqlPassenger = @"
            INSERT INTO rides_by_passenger (
                passenger_id, created_at, ride_id, driver_id, 
                pickup_address, dropoff_address, status, total_fare, vehicle_type
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";

                var psPassenger = await _session.PrepareAsync(cqlPassenger);
                var stPassenger = psPassenger.Bind(
                    ride.PassengerId, ride.CreatedAt, ride.RideId, ride.DriverId,
                    ride.PickupAddress, ride.DropoffAddress, ride.Status, ride.TotalFare, ride.VehicleType
                );

                // 3. (Tùy chọn) Nếu lúc tạo ride đã có driver (ví dụ book xe tiện chuyến), 
                // thì insert luôn vào rides_by_driver. Nhưng thường lúc tạo là status='requesting' chưa có tài xế,
                // nên đoạn này có thể bỏ qua, chờ lúc tài xế nhận chuyến thì update sau.

                // 4. Insert vào rides_by_status (Để Admin hoặc System quét các chuyến đang 'requesting')
                var cqlStatus = @"
            INSERT INTO rides_by_status (
                status, created_at, ride_id, passenger_id, driver_id, total_fare
            ) VALUES (?, ?, ?, ?, ?, ?)";

                var psStatus = await _session.PrepareAsync(cqlStatus);
                var stStatus = psStatus.Bind(
                    ride.Status, ride.CreatedAt, ride.RideId, ride.PassengerId, ride.DriverId, ride.TotalFare
                );

                // GỘP LẠI CHẠY 1 LẦN
                var batch = new BatchStatement();
                batch.Add(stMain);
                batch.Add(stPassenger);
                batch.Add(stStatus);

                await _session.ExecuteAsync(batch);

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
                // ... code query giữ nguyên ...
                var cql = "SELECT * FROM rides WHERE ride_id = ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(rideId));
                var row = result.FirstOrDefault();

                if (row == null) return null;

                return MapRowToRide(row);
            }
            catch (Exception ex)
            {
                // 👇 SỬA CHỖ NÀY: Đừng return null nữa, throw lỗi ra để thấy nguyên nhân!
                _logger.LogError(ex, "Error getting ride by ID: " + ex.Message);
                throw;
            }
        }

        public async Task<bool> UpdateRideAsync(Ride ride)
        {
            try
            {
                // BƯỚC 1: Phải lấy thông tin cũ trong DB ra trước 
                // (Để biết status cũ là gì mà xóa bên bảng rides_by_status)
                var oldRideCql = "SELECT status, created_at FROM rides WHERE ride_id = ?";
                var oldRideRow = (await _session.ExecuteAsync(
                    (await _session.PrepareAsync(oldRideCql)).Bind(ride.RideId)
                )).FirstOrDefault();

                if (oldRideRow == null) return false;

                string oldStatus = oldRideRow.GetValue<string>("status");
                DateTime createdAt = oldRideRow.GetValue<DateTime>("created_at"); // Cần cái này vì nó là Clustering Key

                // BƯỚC 2: Chuẩn bị Batch (Gom tất cả hành động vào 1 cục)
                var batch = new BatchStatement();

                // 2.1. Update bảng chính (rides)
                var cqlMain = @"
            UPDATE rides SET 
                driver_id = ?, status = ?, accepted_at = ?, started_at = ?, completed_at = ?,
                cancelled_at = ?, cancellation_reason = ?, actual_distance = ?, actual_duration = ?,
                driver_rating = ?, passenger_rating = ?, notes = ?
            WHERE ride_id = ?
        ";
                var stMain = await _session.PrepareAsync(cqlMain);
                batch.Add(stMain.Bind(
                    ride.DriverId, ride.Status, ride.AcceptedAt, ride.StartedAt, ride.CompletedAt,
                    ride.CancelledAt, ride.CancellationReason, ride.ActualDistance, ride.ActualDuration,
                    ride.DriverRating, ride.PassengerRating, ride.Notes, ride.RideId
                ));

                // 2.2. Update bảng rides_by_passenger (Cập nhật status cho khách thấy)
                var cqlPassenger = "UPDATE rides_by_passenger SET status = ? WHERE passenger_id = ? AND created_at = ? AND ride_id = ?";
                var stPassenger = await _session.PrepareAsync(cqlPassenger);
                batch.Add(stPassenger.Bind(ride.Status, ride.PassengerId, createdAt, ride.RideId));

                // 2.3. Update bảng rides_by_driver (Nếu đã có tài xế)
                if (ride.DriverId != null)
                {
                    // Lưu ý: Nếu status chuyển từ 'requesting' sang 'accepted', lúc này mới có DriverId.
                    // Nên insert vào bảng này thay vì update nếu chưa có record. 
                    // Nhưng để đơn giản, ta dùng INSERT (trong Cassandra INSERT đè lên record cũ cũng tính là Update)
                    var cqlDriver = @"
                INSERT INTO rides_by_driver (driver_id, created_at, ride_id, status, dropoff_address, passenger_id, pickup_address, total_fare, vehicle_type)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ";
                    var stDriver = await _session.PrepareAsync(cqlDriver);
                    batch.Add(stDriver.Bind(
                        ride.DriverId, createdAt, ride.RideId, ride.Status,
                        ride.DropoffAddress, ride.PassengerId, ride.PickupAddress, ride.TotalFare, ride.VehicleType
                    ));
                }

                // 2.4. XỬ LÝ BẢNG rides_by_status (Quan trọng nhất)
                if (oldStatus != ride.Status) // Chỉ làm khi trạng thái thay đổi
                {
                    // A. Xóa dòng ở trạng thái cũ (Ví dụ xóa dòng ở cột 'requesting')
                    var cqlDeleteOld = "DELETE FROM rides_by_status WHERE status = ? AND created_at = ? AND ride_id = ?";
                    var stDeleteOld = await _session.PrepareAsync(cqlDeleteOld);
                    batch.Add(stDeleteOld.Bind(oldStatus, createdAt, ride.RideId));

                    // B. Thêm dòng vào trạng thái mới (Ví dụ thêm vào cột 'accepted')
                    var cqlInsertNew = @"
                INSERT INTO rides_by_status (status, created_at, ride_id, driver_id, passenger_id, total_fare)
                VALUES (?, ?, ?, ?, ?, ?)
            ";
                    var stInsertNew = await _session.PrepareAsync(cqlInsertNew);
                    batch.Add(stInsertNew.Bind(ride.Status, createdAt, ride.RideId, ride.DriverId, ride.PassengerId, ride.TotalFare));
                }

                // BƯỚC 3: Bùm! Thực thi tất cả
                await _session.ExecuteAsync(batch);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating ride full flow");
                return false;
            }
        }

        public async Task<List<RideHistoryDto>> GetRidesByPassengerAsync(Guid passengerId, int limit = 20)
        {
            try
            {
                var cql = "SELECT * FROM rides_by_passenger WHERE passenger_id = ? LIMIT ?";
                var statement = await _session.PrepareAsync(cql);
                var result = await _session.ExecuteAsync(statement.Bind(passengerId, limit));

                // 👇 QUAN TRỌNG: Phải dùng hàm Map sang DTO
                return result.Select(MapRowToRideHistory).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rides by passenger");
                return new List<RideHistoryDto>();
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
        public async Task<bool> CancelRideAsync(Guid rideId, string reason)
        {
            try
            {
                // BƯỚC 1: Lấy dữ liệu cũ để biết đường mà lần
                // Cần: Status cũ (để xóa trong rides_by_status), DriverId (để giải phóng tài xế), CreatedAt (làm key)
                var queryGet = "SELECT * FROM rides WHERE ride_id = ?";
                var row = (await _session.ExecuteAsync((await _session.PrepareAsync(queryGet)).Bind(rideId))).FirstOrDefault();

                if (row == null) return false;

                var ride = MapRowToRide(row); // Tận dụng hàm Map có sẵn

                // Validation logic: Chỉ cho hủy khi chưa hoàn thành
                if (ride.Status == "completed" || ride.Status == "cancelled")
                {
                    _logger.LogWarning("Cannot cancel ride {RideId} with status {Status}", rideId, ride.Status);
                    return false;
                }

                var cancelledAt = DateTime.UtcNow;

                // BƯỚC 2: Chuẩn bị BATCH
                var batch = new BatchStatement();

                // 2.1. Update bảng chính (rides)
                var cqlMain = "UPDATE rides SET status = 'cancelled', cancelled_at = ?, cancellation_reason = ? WHERE ride_id = ?";
                var stMain = await _session.PrepareAsync(cqlMain);
                batch.Add(stMain.Bind(cancelledAt, reason, rideId));

                // 2.2. Update bảng rides_by_passenger
                var cqlPass = "UPDATE rides_by_passenger SET status = 'cancelled' WHERE passenger_id = ? AND created_at = ? AND ride_id = ?";
                var stPass = await _session.PrepareAsync(cqlPass);
                batch.Add(stPass.Bind(ride.PassengerId, ride.CreatedAt, rideId));

                // 2.3. Update bảng rides_by_driver (Nếu đã có tài xế)
                if (ride.DriverId != null)
                {
                    // Update status chuyến đi của tài xế thành cancelled
                    var cqlDriver = "UPDATE rides_by_driver SET status = 'cancelled' WHERE driver_id = ? AND created_at = ? AND ride_id = ?";
                    var stDriver = await _session.PrepareAsync(cqlDriver);
                    batch.Add(stDriver.Bind(ride.DriverId, ride.CreatedAt, rideId));

                    // QUAN TRỌNG: Giải phóng tài xế (Set is_available = true)
                    // Để nó đi nhận khách khác, không là nó đứng đường đó.
                    var cqlFreeDriver = "UPDATE drivers SET is_available = true, updated_at = ? WHERE driver_id = ?";
                    var stFreeDriver = await _session.PrepareAsync(cqlFreeDriver);
                    batch.Add(stFreeDriver.Bind(DateTime.UtcNow, ride.DriverId));

                    // Cập nhật cả bảng drivers_by_location nữa cho đồng bộ
                    // (Đoạn này cần geohash hiện tại của tài xế, nếu ko có thì bỏ qua hoặc query thêm, 
                    // nhưng tạm thời update bảng chính drivers là quan trọng nhất).
                }

                // 2.4. Xử lý rides_by_status (Xóa cũ - Thêm mới vào cột 'cancelled')
                // A. Xóa ở trạng thái cũ (VD: đang 'requesting' hoặc 'accepted')
                var cqlDelStatus = "DELETE FROM rides_by_status WHERE status = ? AND created_at = ? AND ride_id = ?";
                var stDelStatus = await _session.PrepareAsync(cqlDelStatus);
                batch.Add(stDelStatus.Bind(ride.Status, ride.CreatedAt, rideId));

                // B. Insert vào trạng thái 'cancelled'
                var cqlInsStatus = @"
            INSERT INTO rides_by_status (status, created_at, ride_id, driver_id, passenger_id, total_fare) 
            VALUES ('cancelled', ?, ?, ?, ?, ?)";
                var stInsStatus = await _session.PrepareAsync(cqlInsStatus);
                batch.Add(stInsStatus.Bind(ride.CreatedAt, rideId, ride.DriverId, ride.PassengerId, ride.TotalFare));

                // BƯỚC 3: Thực thi
                await _session.ExecuteAsync(batch);

                _logger.LogInformation("Ride {RideId} cancelled successfully", rideId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error canceling ride");
                return false;
            }
        }
        public async Task<DriverInfo?> GetDriverInfoWithPhoneAsync(Guid driverId)
        {
            try
            {
                // 1. Lấy thông tin Driver (để lấy user_id và vehicle_id)
                var cqlDriver = "SELECT user_id, vehicle_id, rating, current_location_lat, current_location_lng FROM drivers WHERE driver_id = ?";
                var psDriver = await _session.PrepareAsync(cqlDriver);
                var driverRow = (await _session.ExecuteAsync(psDriver.Bind(driverId))).FirstOrDefault();

                if (driverRow == null) return null;

                var userId = driverRow.GetValue<Guid>("user_id");
                var vehicleId = driverRow.GetValue<Guid>("vehicle_id");

                // Lưu ý: Cassandra lưu decimal, code mày dùng double -> phải ép kiểu
                var rating = (double)driverRow.GetValue<decimal>("rating");
                var lat = driverRow.GetValue<double>("current_location_lat");
                var lng = driverRow.GetValue<double>("current_location_lng");

                // 2. Lấy User (ĐỂ LẤY SỐ ĐIỆN THOẠI & TÊN)
                var cqlUser = "SELECT full_name, phone_number FROM users WHERE user_id = ?";
                var psUser = await _session.PrepareAsync(cqlUser);
                var userRow = (await _session.ExecuteAsync(psUser.Bind(userId))).FirstOrDefault();

                string phone = userRow?.GetValue<string>("phone_number") ?? "";
                string name = userRow?.GetValue<string>("full_name") ?? "Tài xế";

                // 3. Lấy Xe (Nếu cần hiển thị tên xe, biển số)
                VehicleInfo? vehicleInfo = null;
                if (vehicleId != Guid.Empty)
                {
                    var cqlVehicle = "SELECT vehicle_type, brand, model, color, license_plate FROM vehicles WHERE vehicle_id = ?";
                    var psVehicle = await _session.PrepareAsync(cqlVehicle);
                    var vRow = (await _session.ExecuteAsync(psVehicle.Bind(vehicleId))).FirstOrDefault();

                    if (vRow != null)
                    {
                        vehicleInfo = new VehicleInfo
                        {
                            VehicleType = vRow.GetValue<string>("vehicle_type"),
                            Brand = vRow.GetValue<string>("brand"),
                            Model = vRow.GetValue<string>("model"),
                            Color = vRow.GetValue<string>("color"),
                            LicensePlate = vRow.GetValue<string>("license_plate")
                        };
                    }
                }

                // 4. Đổ dữ liệu vào Model DriverInfo của mày
                return new DriverInfo
                {
                    DriverId = driverId.ToString(), // Model mày để string nên phải .ToString()
                    FullName = name,
                    PhoneNumber = phone, // 👈 SỐ ĐIỆN THOẠI ĐÃ LẤY ĐƯỢC
                    Rating = rating,
                    Vehicle = vehicleInfo,
                    CurrentLocation = new Location
                    {
                        Latitude = lat,
                        Longitude = lng
                    },
                    EstimatedArrival = 5 // Fake tạm hoặc tính toán nếu cần
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi lấy thông tin tài xế kèm SĐT");
                return null;
            }
        }
        private RideHistoryDto MapRowToRideHistory(Row row)
        {
            return new RideHistoryDto
            {
                RideId = row.GetValue<Guid>("ride_id"),
                // Dùng GetValueSafe nếu sợ null, hoặc GetValue nếu chắc chắn có
                CreatedAt = row.GetValue<DateTime>("created_at"),
                PickupAddress = row.GetValue<string>("pickup_address") ?? "",
                DropoffAddress = row.GetValue<string>("dropoff_address") ?? "",
                TotalFare = row.GetValue<decimal>("total_fare"),
                Status = row.GetValue<string>("status") ?? "",
                VehicleType = row.GetValue<string>("vehicle_type") ?? "",
                // PaymentMethod = "cash" // Mặc định nếu DB chưa có cột này
            };
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
                EstimatedDistance = row.GetValue<decimal>("estimated_distance"),
                ActualDistance = row.GetValue<decimal?>("actual_distance"),
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
                DriverRating = null,
                PassengerRating = null,
                Notes = null,
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