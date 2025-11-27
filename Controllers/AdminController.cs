using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using api_ride.Services;
using api_ride.Models.DTOs;
using api_ride.Models;
using System.Security.Claims;

namespace api_ride.Controllers
{
    /// <summary>
    /// Controller quản lý Admin - Chỉ dành cho Role Admin
    /// Cung cấp API để quản lý user, tài xế, chuyến xe và giám sát hệ thống
    /// </summary>
    [ApiController]
    [Route("api/admin")]

    public class AdminController : ControllerBase
    {
        private readonly ICassandraService _cassandraService;
        private readonly ILogger<AdminController> _logger;
        private readonly IFirebaseService _firebaseService;

        public AdminController(
            ICassandraService cassandraService,
            ILogger<AdminController> logger,
            IFirebaseService firebaseService)
        {
            _cassandraService = cassandraService;
            _logger = logger;
            _firebaseService = firebaseService;
        }

        // =====================================================
        // PHẦN 1: QUẢN LÝ NGƯỜI DÙNG (USERS)
        // =====================================================

        /// <summary>
        /// Lấy thông tin chi tiết User theo ID
        /// GET: api/admin/users/{id}
        /// </summary>
        /// 
        
        [HttpGet("users/{id}")]
        public async Task<ActionResult<User>> GetUserById(Guid id)
        {
            try
            {
                var user = await _cassandraService.GetUserByIdAsync(id);
                if (user == null)
                {
                    _logger.LogWarning("Admin queried non-existent user: {Id}", id);
                    return NotFound(new { message = "User not found" });
                }

                _logger.LogInformation("Admin viewed user details: {Id}", id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetUserById for {Id}", id);
                return StatusCode(500, new { message = "Internal server error", error = ex.Message });
            }
        }

        /// <summary>
        /// Tìm User theo Email (Sử dụng bảng lookup users_by_email)
        /// GET: api/admin/users/by-email?email=xxx@xxx.com
        /// </summary>
        [HttpGet("users/by-email")]
        public async Task<ActionResult<User>> GetUserByEmail([FromQuery] string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return BadRequest(new { message = "Email is required" });

            try
            {
                // Hàm này đã tối ưu bằng cách query bảng users_by_email trước
                var user = await _cassandraService.GetUserByEmailAsync(email);
                if (user == null)
                    return NotFound(new { message = "User not found" });

                _logger.LogInformation("Admin searched user by email: {Email}", email);
                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetUserByEmail for {Email}", email);
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Lấy danh sách tất cả User (⚠️ CHÚ Ý: Query toàn bộ table, chỉ dùng cho DB nhỏ)
        /// GET: api/admin/users?limit=50
        /// </summary>
        [HttpGet("users")]
        public async Task<ActionResult> GetAllUsers([FromQuery] int limit = 50)
        {
            try
            {
                _logger.LogWarning("Admin is scanning entire 'users' table. Consider pagination for large datasets.");

                // Query toàn bộ bảng users (Không tối ưu cho data lớn)
                var cql = "SELECT * FROM users LIMIT ?";
                var result = await _cassandraService.ExecuteQueryAsync(cql, new object[] { limit });

                var users = result.Select(row => new
                {
                    user_id = row.GetValue<Guid>("user_id"),
                    full_name = row.GetValue<string>("full_name"),
                    email = row.GetValue<string>("email"),
                    phone_number = row.GetValue<string>("phone_number"),
                    user_type = row.GetValue<string>("user_type"),
                    status = row.GetValue<string>("status"),
                    created_at = row.GetValue<DateTime>("created_at")
                }).ToList();

                return Ok(new { total = users.Count, users });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all users");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Cập nhật trạng thái User (active/suspended/banned)
        /// PUT: api/admin/users/{id}/status
        /// </summary>
        [HttpPut("users/{id}/status")]
        public async Task<ActionResult> UpdateUserStatus(Guid id, [FromBody] UpdateUserStatusRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Status))
                return BadRequest(new { message = "Status is required" });

            // Validate status values
            var validStatuses = new[] { "active", "suspended", "banned" };
            if (!validStatuses.Contains(request.Status.ToLower()))
                return BadRequest(new { message = "Invalid status. Must be: active, suspended, or banned" });

            try
            {
                var user = await _cassandraService.GetUserByIdAsync(id);
                if (user == null) return NotFound(new { message = "User not found" });

                // Cập nhật Status (Cần mở rộng UpdateUserAsync để hỗ trợ update Status)
                user.Status = request.Status.ToLower();
                user.UpdatedAt = DateTime.UtcNow;

                var success = await _cassandraService.UpdateUserAsync(user);
                if (!success)
                    return StatusCode(500, new { message = "Failed to update user status" });

                _logger.LogInformation("Admin changed user {Id} status to {Status}", id, request.Status);
                return Ok(new { message = $"User status updated to {request.Status}" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user status for {Id}", id);
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        // =====================================================
        // PHẦN 2: QUẢN LÝ TÀI XẾ (DRIVERS)
        // =====================================================

        /// <summary>
        /// Lấy thông tin chi tiết Tài xế theo ID
        /// GET: api/admin/drivers/{id}
        /// </summary>
        /// [HttpGet("diver")]
        [HttpGet("drivers")]
        public async Task<ActionResult> GetAllDrivers([FromQuery] int limit = 50)
        {
            try
            {
                _logger.LogWarning("Admin is scanning 'drivers' table. Consider pagination for large datasets.");

                // Cassandra không hỗ trợ offset trực tiếp, nên giới hạn dùng limit + token
                var cql = "SELECT * FROM ride.drivers LIMIT ?";
                var result = await _cassandraService.ExecuteQueryAsync(cql, new object[] { limit });
                var drivers = result.Select(row => new
                {
                    driver_id = row.GetValue<Guid>("driver_id"),
                    user_id = row.GetValue<Guid>("user_id"),
                    completed_trips = row.GetValue<int?>("completed_trips"),
                    is_available = row.GetValue<bool?>("is_available"),
                    online_status = row.GetValue<string>("online_status"),

                    rating = row.GetValue<decimal?>("rating"),
                    total_earnings = row.GetValue<decimal?>("total_earnings"),

                    current_location_lat = row.GetValue<double?>("current_location_lat"),
                    current_location_lng = row.GetValue<double?>("current_location_lng"),
                    license_number = row.GetValue<string>("license_number"),

                    // Chuyển từ LocalDate sang DateTime
                    license_expiry = row.GetValue<Cassandra.LocalDate?>("license_expiry")?.ToDateTimeOffset(),

                    created_at = row.GetValue<DateTime?>("created_at"),
                    updated_at = row.GetValue<DateTime?>("updated_at")
                }).ToList();




                return Ok(new { total = drivers.Count, drivers });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching drivers");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        [HttpGet("drivers/{id}")]
        public async Task<ActionResult<Driver>> GetDriverById(Guid id)
        {
            try
            {
                var driver = await _cassandraService.GetDriverByIdAsync(id);
                if (driver == null)
                    return NotFound(new { message = "Driver not found" });

                // Lấy thêm thông tin User để hiển thị đầy đủ
                var user = await _cassandraService.GetUserByIdAsync(driver.UserId);
                var vehicle = await _cassandraService.GetVehicleByIdAsync(driver.VehicleId);

                return Ok(new
                {
                    driver,
                    user_info = user != null ? new
                    {
                        full_name = user.FullName,
                        email = user.Email,
                        phone = user.Phone,
                        status = user.Status
                    } : null,
                    vehicle_info = vehicle
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting driver {Id}", id);
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Lấy lịch sử chuyến đi của Tài xế (Từ bảng rides_by_driver - Tối ưu)
        /// GET: api/admin/drivers/{id}/rides?limit=20
        /// </summary>
        [HttpGet("drivers/{id}/rides")]
        public async Task<ActionResult> GetDriverRides(Guid id, [FromQuery] int limit = 20)
        {
            try
            {
                // Query từ bảng rides_by_driver (Partition Key = driver_id, tối ưu nhất)
                var cql = "SELECT * FROM rides_by_driver WHERE driver_id = ? LIMIT ?";
                var result = await _cassandraService.ExecuteQueryAsync(cql, new object[] { id, limit });

                var rides = result.Select(row => new
                {
                    ride_id = row.GetValue<Guid>("ride_id"),
                    created_at = row.GetValue<DateTime>("created_at"),
                    status = row.GetValue<string>("status"),
                    pickup_address = row.GetValue<string>("pickup_address"),
                    dropoff_address = row.GetValue<string>("dropoff_address"),
                    total_fare = row.GetValue<decimal>("total_fare"),
                    vehicle_type = row.GetValue<string>("vehicle_type")
                }).ToList();

                return Ok(new { driver_id = id, total_rides = rides.Count, rides });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rides for driver {Id}", id);
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Cập nhật trạng thái Online/Offline của Tài xế
        /// PUT: api/admin/drivers/{id}/online-status
        /// </summary>
        [HttpPut("drivers/{id}/online-status")]
        public async Task<IActionResult> UpdateDriverOnlineStatus(Guid id, [FromBody] UpdateOnlineStatusRequest request)
        {
            var validStatuses = new[] { "online", "offline", "busy" };
            if (!validStatuses.Contains(request.OnlineStatus.ToLower()))
                return BadRequest(new { message = "Invalid status. Must be: online, offline, or busy" });

            try
            {
                var cql = "UPDATE drivers SET online_status = ?, updated_at = ? WHERE driver_id = ?";
                await _cassandraService.ExecuteAsync(cql, new object[]
                {
                    request.OnlineStatus.ToLower(),
                    DateTime.UtcNow,
                    id
                });

                _logger.LogInformation("Admin changed driver {Id} online status to {Status}", id, request.OnlineStatus);
                return Ok(new { message = $"Driver online status updated to {request.OnlineStatus}" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating driver online status");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Lấy danh sách Tài xế theo khu vực Geohash (Từ bảng drivers_by_location)
        /// GET: api/admin/drivers/location/{geohash}
        /// </summary>
        [HttpGet("drivers/location/{geohash}")]
        public async Task<ActionResult<List<DriverByLocation>>> GetDriversByGeohash(string geohash)
        {
            try
            {
                var drivers = await _cassandraService.GetDriversByLocationAsync(geohash);

                if (!drivers.Any())
                {
                    return NotFound(new
                    {
                        message = $"No drivers found in geohash {geohash}",
                        geohash
                    });
                }

                _logger.LogInformation("Admin queried {Count} drivers in geohash {Hash}", drivers.Count, geohash);
                return Ok(new { geohash, total = drivers.Count, drivers });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting drivers by geohash {Hash}", geohash);
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        // =====================================================
        // PHẦN 3: QUẢN LÝ CHUYẾN ĐI (RIDES)
        // =====================================================

        /// <summary>
        /// Lấy danh sách chuyến đi đang hoạt động (Từ bảng rides_by_status - Tối ưu)
        /// GET: api/admin/rides/active?status=requesting
        /// </summary>
        [HttpGet("rides/active")]
        public async Task<ActionResult> GetActiveRides([FromQuery] string? status = null)
        {
            try
            {
                // Nếu ko chỉ định status cụ thể, query tất cả status đang active
                var activeStatuses = !string.IsNullOrEmpty(status)
                    ? new[] { status }
                    : new[] { "requesting", "accepted", "arrived", "in_progress" };

                var allRides = new List<object>();

                foreach (var s in activeStatuses)
                {
                    // Query bảng rides_by_status (Partition Key = status, cực nhanh)
                    var cql = "SELECT * FROM rides_by_status WHERE status = ? LIMIT 100";
                    var result = await _cassandraService.ExecuteQueryAsync(cql, new object[] { s });

                    var rides = result.Select(row => new
                    {
                        ride_id = row.GetValue<Guid>("ride_id"),
                        status = row.GetValue<string>("status"),
                        created_at = row.GetValue<DateTime>("created_at"),
                        passenger_id = row.GetValue<Guid>("passenger_id"),
                        driver_id = row.GetValue<Guid?>("driver_id"),
                        total_fare = row.GetValue<decimal>("total_fare")
                    });

                    allRides.AddRange(rides);
                }

                _logger.LogInformation("Admin queried active rides: {Count} found", allRides.Count);
                return Ok(new { total = allRides.Count, rides = allRides });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error querying active rides");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Lấy chi tiết chuyến đi đầy đủ (Từ bảng rides)
        /// GET: api/admin/rides/{id}
        /// </summary>
        [HttpGet("rides/{id}")]
        public async Task<ActionResult> GetRideDetails(Guid id)
        {
            try
            {
                var ride = await _cassandraService.GetRideByIdAsync(id);
                if (ride == null)
                    return NotFound(new { message = "Ride not found" });

                // Lấy thêm thông tin Passenger & Driver
                var passenger = await _cassandraService.GetUserByIdAsync(ride.PassengerId);

                User? driver = null;
                if (ride.DriverId != null)
                {
                    var driverInfo = await _cassandraService.GetDriverByIdAsync(ride.DriverId.Value);
                    if (driverInfo != null)
                        driver = await _cassandraService.GetUserByIdAsync(driverInfo.UserId);
                }

                return Ok(new
                {
                    ride,
                    passenger_info = passenger != null ? new
                    {
                        full_name = passenger.FullName,
                        phone = passenger.Phone,
                        email = passenger.Email
                    } : null,
                    driver_info = driver != null ? new
                    {
                        full_name = driver.FullName,
                        phone = driver.Phone,
                        email = driver.Email
                    } : null
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting ride details {Id}", id);
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        /// <summary>
        /// Admin HỦY CHUYẾN đi (Với quyền tối cao)
        /// POST: api/admin/rides/{id}/force-cancel
        /// </summary>
        [HttpPost("rides/{id}/force-cancel")]
        public async Task<IActionResult> ForceCancelRide(Guid id, [FromBody] AdminCancelRequest request)
        {
            if (string.IsNullOrEmpty(request.Reason))
                return BadRequest(new { message = "Cancellation reason is required" });

            try
            {
                var adminUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var adminName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Admin";

                // Hàm CancelRideAsync đã xử lý Update 4 bảng + Giải phóng tài xế
                var success = await _cassandraService.CancelRideAsync(
                    id,
                    $"[ADMIN CANCEL by {adminName}] {request.Reason}"
                );

                if (!success)
                    return BadRequest(new
                    {
                        message = "Cannot cancel ride (Already completed/cancelled or not found)"
                    });

                // Cập nhật Firebase để App biết ngay
                await _firebaseService.UpdateRideStatusAsync(id.ToString(), "cancelled");

                _logger.LogWarning("Admin {AdminId} force-cancelled ride {RideId}. Reason: {Reason}",
                    adminUserId, id, request.Reason);

                return Ok(new
                {
                    message = "Ride force-cancelled successfully by admin",
                    ride_id = id
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error force-cancelling ride {Id}", id);
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Thống kê tổng quan hệ thống (Dashboard Admin)
        /// GET: api/admin/dashboard/stats
        /// </summary>
        [HttpGet("dashboard/stats")]
        public async Task<ActionResult> GetDashboardStats()
        {
            try
            {
                // ⚠️ LƯU Ý: Query COUNT(*) trên Cassandra rất chậm với data lớn
                // Nên dùng cơ chế đếm riêng hoặc cache kết quả

                _logger.LogWarning("Admin is running COUNT queries. This may be slow on large datasets.");

                // Đếm User (Query toàn bảng - chậm)
                var userCountCql = "SELECT COUNT(*) as total FROM users";
                var userCount = (await _cassandraService.ExecuteQueryAsync(userCountCql, Array.Empty<object>()))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                // Đếm Driver (Query toàn bảng - chậm)
                var driverCountCql = "SELECT COUNT(*) as total FROM drivers";
                var driverCount = (await _cassandraService.ExecuteQueryAsync(driverCountCql, Array.Empty<object>()))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                // ✅ Đếm Ride theo status (Query theo Partition Key - NHANH)
                // ⚠️ BỎ ALLOW FILTERING vì status đã là Partition Key rồi!
                var requestingCql = "SELECT COUNT(*) as total FROM rides_by_status WHERE status = ?";
                var requestingCount = (await _cassandraService.ExecuteQueryAsync(requestingCql, new object[] { "requesting" }))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                var acceptedCql = "SELECT COUNT(*) as total FROM rides_by_status WHERE status = ?";
                var acceptedCount = (await _cassandraService.ExecuteQueryAsync(acceptedCql, new object[] { "accepted" }))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                var inProgressCql = "SELECT COUNT(*) as total FROM rides_by_status WHERE status = ?";
                var inProgressCount = (await _cassandraService.ExecuteQueryAsync(inProgressCql, new object[] { "in_progress" }))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                var completedCql = "SELECT COUNT(*) as total FROM rides_by_status WHERE status = ?";
                var completedCount = (await _cassandraService.ExecuteQueryAsync(completedCql, new object[] { "completed" }))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                var cancelledCql = "SELECT COUNT(*) as total FROM rides_by_status WHERE status = ?";
                var cancelledCount = (await _cassandraService.ExecuteQueryAsync(cancelledCql, new object[] { "cancelled" }))
                    .FirstOrDefault()?.GetValue<long>("total") ?? 0;

                return Ok(new
                {
                    system_stats = new
                    {
                        total_users = userCount,
                        total_drivers = driverCount
                    },
                    ride_stats = new
                    {
                        requesting = requestingCount,      // Đang tìm xe
                        accepted = acceptedCount,          // Tài xế đã nhận
                        in_progress = inProgressCount,     // Đang chạy
                        completed = completedCount,        // Hoàn thành
                        cancelled = cancelledCount,        // Đã hủy
                        total_active = requestingCount + acceptedCount + inProgressCount
                    },
                    generated_at = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating dashboard stats");
                return StatusCode(500, new { message = "Internal server error" });
            }
        }

        // =====================================================
        // DTO CLASSES (Request Models)
        // =====================================================

        public class UpdateUserStatusRequest
        {
            public string Status { get; set; } = string.Empty;
        }

        public class UpdateOnlineStatusRequest
        {
            public string OnlineStatus { get; set; } = string.Empty;
        }

        public class AdminCancelRequest
        {
            public string Reason { get; set; } = "Administrative override";
        }
    }
}