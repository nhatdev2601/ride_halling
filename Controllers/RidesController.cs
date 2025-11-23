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

        public RidesController(
            FareCalculationService fareService,
            IRideRepository rideRepository,
            IDriverService driverService,
            ILogger<RidesController> logger)
        {
            _fareService = fareService;
            _rideRepository = rideRepository;
            _driverService = driverService;
            _logger = logger;
        }

        [HttpPost("calculate-fare")]
        [AllowAnonymous]
        public ActionResult<CalculateFareResponse> CalculateFare([FromBody] CalculateFareRequest request)
        {
            try
            {
                _logger.LogInformation("📥 Calculating fare for {VehicleType} from {Pickup} to {Destination}", 
                    request.VehicleType, request.PickupLocation.Address, request.DestinationLocation.Address);

                var result = _fareService.CalculateFare(request);

                _logger.LogInformation("💰 Total fare calculated: {TotalFare:N0} VNĐ", result.TotalFare);

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating fare");
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpPost("book")]
        public async Task<ActionResult<CreateRideResponse>> BookRide([FromBody] CreateRideRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { error = "User not authenticated" });
                }

                _logger.LogInformation("🚗 User {UserId} is booking a ride", userId);

                if (request.PickupLocation == null || request.DestinationLocation == null)
                {
                    return BadRequest(new { error = "Pickup and destination locations are required" });
                }

                if (string.IsNullOrEmpty(request.VehicleType))
                {
                    return BadRequest(new { error = "Vehicle type is required" });
                }

                var distance = request.Distance;
                
                if (distance <= 0)
                {
                    return BadRequest(new { error = "loi khong co khoang cach" });
                }

                var fareRequest = new CalculateFareRequest
                {
                    PickupLocation = request.PickupLocation,
                    DestinationLocation = request.DestinationLocation,
                    VehicleType = request.VehicleType,
                    Distance = distance
                };

                var fareInfo = _fareService.CalculateFare(fareRequest);
                var rideId = await _rideRepository.CreateRideAsync(request, userId, fareInfo);

                _logger.LogInformation("✅ Created ride: {RideId}", rideId);

                var driver = await _driverService.FindNearestDriverAsync(
                    request.PickupLocation.Latitude,
                    request.PickupLocation.Longitude,
                    request.VehicleType
                );

                if (driver != null)
                {
                    await _rideRepository.UpdateRideStatusAsync(rideId, "accepted", driver.DriverId);
                    _logger.LogInformation("👨‍✈️ Assigned driver: {DriverName}", driver.FullName);
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
                _logger.LogError(ex, "Error booking ride");
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
        public async Task<ActionResult<List<Models.Ride>>> GetUserRides()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
                
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized();
                }

                List<Models.Ride> rides;
                
                if (userRole == "passenger")
                {
                    rides = await _rideRepository.GetRidesByPassengerAsync(userId);
                }
                else if (userRole == "driver")
                {
                    rides = await _rideRepository.GetRidesByDriverAsync(userId);
                }
                else
                {
                    return BadRequest(new { error = "Invalid user role" });
                }

                return Ok(rides);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user rides");
                return StatusCode(500, new { error = "Internal server error" });
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