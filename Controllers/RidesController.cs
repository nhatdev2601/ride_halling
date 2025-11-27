using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using api_ride.Models.DTOs;
using api_ride.Services;
using api_ride.Repositories;
using System.Security.Claims;

namespace api_ride.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RidesController : ControllerBase
    {
        private readonly FareCalculationService _fareService;
        private readonly IRideRepository _rideRepository;
        private readonly IDriverService _driverService;
        private readonly ILogger<RidesController> _logger;
        private readonly ICassandraService _cassandraService;

        public RidesController(
            FareCalculationService fareService,
            IRideRepository rideRepository,
            IDriverService driverService,
            ILogger<RidesController> logger,
            ICassandraService cassandraService)
        {
            _fareService = fareService;
            _rideRepository = rideRepository;
            _driverService = driverService;
            _cassandraService = cassandraService;

            _logger = logger;
        }

        [HttpPost("calculate-fare")]
        [AllowAnonymous]
        public async Task<ActionResult<CalculateFareResponse>> CalculateFare([FromBody] CalculateFareRequest request)
        {
            try
            {
                // Lấy User ID để check xem user dùng mã chưa
                var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                Guid userId = Guid.Empty;
                if (!string.IsNullOrEmpty(userIdString)) Guid.TryParse(userIdString, out userId);

                // Gọi hàm Async mới
                var result = await _fareService.CalculateFareAsync(request, userId);

                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpPost("book")]
        public async Task<ActionResult<CreateRideResponse>> BookRide([FromBody] CreateRideRequest request)
        {
            try
            {
                var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdString)) return Unauthorized();
                Guid.TryParse(userIdString, out var userId);

                // Tính lại giá lần cuối để chốt đơn (tránh hack giá ở client)
                var fareRequest = new CalculateFareRequest
                {
                    PickupLocation = request.PickupLocation,
                    DestinationLocation = request.DestinationLocation,
                    VehicleType = request.VehicleType,
                    Distance = request.Distance,
                    PromoCode = request.PromoCode // 👇 Truyền mã vào để tính giảm giá
                };

                var fareInfo = await _fareService.CalculateFareAsync(fareRequest, userId);

                // Tạo chuyến đi
                var rideId = await _rideRepository.CreateRideAsync(request, userIdString, fareInfo);

                // 👇 QUAN TRỌNG: Nếu có giảm giá, lưu vào DB là user này đã dùng mã
                if (!string.IsNullOrEmpty(request.PromoCode) && fareInfo.Discount > 0)
                {
                    await _cassandraService.SaveUserPromoUsageAsync(userId, request.PromoCode, Guid.Parse(rideId), (decimal)fareInfo.Discount);
                    await _cassandraService.IncrementPromoUsageAsync(request.PromoCode);
                }

                // Tìm tài xế (Mock)
                var driver = await _driverService.FindNearestDriverAsync(
                    request.PickupLocation.Latitude, request.PickupLocation.Longitude, request.VehicleType
                );

                if (driver != null)
                {
                    await _rideRepository.UpdateRideStatusAsync(rideId, "accepted", driver.DriverId);
                }

                return Ok(new CreateRideResponse
                {
                    RideId = rideId,
                    Status = driver != null ? "accepted" : "requesting",
                    TotalFare = fareInfo.TotalFare,
                    EstimatedArrival = driver?.EstimatedArrival ?? 0,
                    AssignedDriver = driver
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Models.Ride>> GetRide(string id)
        {
            try
            {
                if (!Guid.TryParse(id, out _))
                {
                    return BadRequest(new { error = "Invalid ride ID format" });
                }

                var ride = await _rideRepository.GetRideByIdAsync(id);
                if (ride == null)
                {
                    return NotFound(new { error = "Ride not found" });
                }

                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
                
                if (userId != ride.PassengerId.ToString() && 
                    userId != ride.DriverId?.ToString() && 
                    userRole != "admin")
                {
                    return Forbid();
                }

                return Ok(ride);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting ride");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }


        [HttpGet]
        public async Task<ActionResult<List<RideHistoryDto>>> GetUserRides()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized();
                }

                if (Guid.TryParse(userId, out var userGuid))
                {
                    
                    var rides = await _rideRepository.GetRidesByPassengerAsync(userId);
                    return Ok(rides);
                }


                return BadRequest(new { error = "Invalid user role" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user rides");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }
        [HttpGet("{id}/details")]
        public async Task<IActionResult> GetRideDetailsWithPhone(Guid id)
        {
            try
            {
                // 1. Lấy thông tin chuyến đi
                var ride = await _cassandraService.GetRideByIdAsync(id);
                if (ride == null) return NotFound(new { message = "Không tìm thấy chuyến xe" });

                DriverInfo? driverInfo = null;

                // 2. Nếu có tài xế -> Gọi hàm lấy SĐT mày vừa viết
                if (ride.DriverId != null)
                {
                    driverInfo = await _cassandraService.GetDriverInfoWithPhoneAsync(ride.DriverId.Value);
                }

                // 3. Trả về cục JSON trực tiếp (Khỏi cần class DTO nào hết)
                // Tao map đúng key 'snake_case' để Flutter đỡ phải sửa
                return Ok(new
                {
                    ride_id = ride.RideId,
                    status = ride.Status,
                    total_fare = ride.TotalFare,

                    // Location cho Map
                    pickup_location_lat = ride.PickupLocationLat,
                    pickup_location_lng = ride.PickupLocationLng,
                    pickup_address = ride.PickupAddress,

                    dropoff_location_lat = ride.DropoffLocationLat,
                    dropoff_location_lng = ride.DropoffLocationLng,
                    dropoff_address = ride.DropoffAddress,

                    vehicle_type = ride.VehicleType,

                    // Thông tin tài xế (Đã có SĐT bên trong)
                    driver_info = driverInfo
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpPut("{id}/status")]
        public async Task<ActionResult> UpdateRideStatus(string id, [FromBody] UpdateRideStatusRequest request)
        {
            try
            {
                if (!Guid.TryParse(id, out _))
                {
                    return BadRequest(new { error = "Invalid ride ID format" });
                }

                var ride = await _rideRepository.GetRideByIdAsync(id);
                if (ride == null)
                {
                    return NotFound(new { error = "Ride not found" });
                }

                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

                if (userRole == "passenger" && userId != ride.PassengerId.ToString())
                {
                    return Forbid();
                }
                
                if (userRole == "driver" && userId != ride.DriverId?.ToString())
                {
                    return Forbid();
                }

                if (!IsValidStatusTransition(ride.Status, request.Status, userRole))
                {
                    return BadRequest(new { error = "Invalid status transition" });
                }

                await _rideRepository.UpdateRideStatusAsync(id, request.Status);

                return Ok(new { message = "Ride status updated successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating ride status");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }


        [HttpPost("{id}/cancel")]
        public async Task<IActionResult> CancelRide(string id, [FromBody] CancelRideRequest request)
        {
            try
            {
                if (!Guid.TryParse(id, out var rideGuid))
                    return BadRequest(new { message = "Invalid ID" });

                // 1. Lấy User ID từ Token (người đang đăng nhập)
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId)) return Unauthorized();

                // 2. Kiểm tra chuyến xe có tồn tại ko
                var ride = await _rideRepository.GetRideByIdAsync(id);
                if (ride == null) return NotFound(new { message = "Ride not found" });

                // 3. Security Check: Chỉ Passenger của chuyến đó hoặc Admin mới được hủy
                // (Nếu sau này làm App cho Tài xế thì thêm check DriverId nữa)
                if (ride.PassengerId.ToString() != userId)
                {
                    return Forbid(); // Mày không phải chủ chuyến xe này!
                }

                // 4. Gọi Service xử lý DB
                var result = await _rideRepository.CancelRideAsync(id, request.Reason);

                if (!result)
                    return BadRequest(new { message = "Could not cancel ride (Already completed or error)" });

                return Ok(new { message = "Ride cancelled successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DTO đơn giản
        public class CancelRideRequest
        {
            public string Reason { get; set; } = "Changed plans";
        }


        private bool IsValidStatusTransition(string currentStatus, string newStatus, string? userRole)
        {
            return (currentStatus, newStatus, userRole) switch
            {
                ("requesting", "cancelled", "passenger") => true,
                ("accepted", "cancelled", "passenger") => true,
                ("accepted", "arrived", "driver") => true,
                ("arrived", "in_progress", "driver") => true,
                ("in_progress", "completed", "driver") => true,
                ("accepted", "cancelled", "driver") => true,
                _ => false
            };
        }
    }

    public class UpdateRideStatusRequest
    {
        public string Status { get; set; } = string.Empty;
        public string? Reason { get; set; }
    }
}