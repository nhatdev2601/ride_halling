using api_ride.Models.DTOs; // Đảm bảo có model Location
using api_ride.Repositories;
using api_ride.Services;
using Microsoft.AspNetCore.Mvc;
using NGeoHash;
using System;
using System.Threading.Tasks;

namespace api_ride.Controllers
{
    [ApiController]
    [Route("api/simulation")]
    public class SimulationController : ControllerBase
    {
        private readonly ICassandraService _cassandraService;
        private readonly IFirebaseService _firebaseService;
        private readonly IRideRepository _rideService; // 👇 Đã sửa tên biến cho khớp logic bên dưới

        // Constructor: Inject các Service vào
        public SimulationController(
            ICassandraService cassandraService,
            IRideRepository rideService,
            IFirebaseService firebaseService)
        {
            _cassandraService = cassandraService;
            _firebaseService = firebaseService;
            _rideService = rideService; // Gán vào biến _rideService
        }

        // ==========================================
        // 1. API CẬP NHẬT VỊ TRÍ GIẢ (Cho Flutter gọi lúc mở Map)
        // ==========================================
        [HttpPost("update-location-fake")]
        public async Task<IActionResult> UpdateDriverLocationFake([FromBody] Location location)
        {
            try
            {
                // 1. ID cứng của thằng tài xế Khang (lấy từ script SQL)
                var driverId = Guid.Parse("99999999-9999-9999-9999-999999999999");

                // 2. Tính Geohash mới (Precision 6)
                var newGeohash = GeoHash.Encode(location.Latitude, location.Longitude, 6);

                // 3. Cập nhật bảng tìm kiếm (drivers_by_location)
                var querySearch = @"
                    INSERT INTO drivers_by_location (geohash, driver_id, latitude, longitude, is_available, rating, updated_at)
                    VALUES (?, ?, ?, ?, true, 5.0, toTimestamp(now()))";

                await _cassandraService.ExecuteAsync(querySearch, new object[] {
                    newGeohash, driverId, location.Latitude, location.Longitude
                });

                // 4. Cập nhật bảng thông tin chính (drivers)
                var queryInfo = @"
                    UPDATE drivers 
                    SET current_location_lat = ?, current_location_lng = ? 
                    WHERE driver_id = ?";

                await _cassandraService.ExecuteAsync(queryInfo, new object[] {
                    location.Latitude, location.Longitude, driverId
                });

                return Ok(new { message = "Đã dời tài xế Khang về vị trí của bạn!" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        // ==========================================
        // 2. API TELEPORT (DỊCH CHUYỂN TỨC THỜI)
        // ==========================================
        [HttpPost("teleport-to-pickup/{rideId}")]
        public async Task<IActionResult> TeleportDriverToPickup(string rideId)
        {
            try
            {
                Console.WriteLine($"👻 [Simulation] Bắt đầu teleport cho Ride: {rideId}");

                // Parse String sang Guid
                if (!Guid.TryParse(rideId, out Guid idGuid)) return BadRequest("ID không đúng định dạng Guid");

                // Gọi Service lấy thông tin chuyến đi
                var ride = await _rideService.GetRideByIdAsync(rideId);

                if (ride == null)
                {
                    Console.WriteLine("❌ Không tìm thấy ride trong DB");
                    return NotFound("Ride not found");
                }

                // Check tọa độ
                Console.WriteLine($"📍 Pickup gốc: {ride.PickupLocationLat}, {ride.PickupLocationLng}");

                if (ride.PickupLocationLat == 0 || ride.PickupLocationLng == 0)
                {
                    return BadRequest("Lỗi: Tọa độ trong DB bằng 0. Kiểm tra lại Model Ride.cs!");
                }

                // Tạo tọa độ Fake (Tài xế ở gần điểm đón 1 chút)
                double fakeLat = ride.PickupLocationLat - 0.002;
                double fakeLng = ride.PickupLocationLng - 0.002;

                // Cấu trúc dữ liệu gửi lên Firebase (Key: lat, lng)
                var updateData = new
                {
                    driver_location = new
                    {
                        lat = fakeLat,
                        lng = fakeLng,
                        bearing = 45 // Góc quay xe
                    }
                };

                // Gửi lên Firebase (PATCH update)
                await _firebaseService.UpdateToFirebaseAsync($"rides/{rideId}", updateData);

                return Ok(new { message = "Xe đã xuất hiện!", location = updateData });
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ Lỗi Simulation: " + ex.Message);
                return BadRequest(ex.Message);
            }
        }

        // ==========================================
        // 3. CÁC API CẬP NHẬT TRẠNG THÁI (Arrived, Start, Complete)
        // ==========================================
        [HttpPost("pickup/{rideId}")]
        public async Task<IActionResult> DriverArrived(string rideId)
        {
            await _rideService.UpdateRideStatusAsync(rideId, "arrived"); // Sửa _rideRepository thành _rideService
            return Ok(new { message = "Tài xế đã đến nơi!" });
        }

        [HttpPost("start/{rideId}")]
        public async Task<IActionResult> StartTrip(string rideId)
        {
            await _rideService.UpdateRideStatusAsync(rideId, "in_progress");
            return Ok(new { message = "Chuyến xe bắt đầu!" });
        }

        [HttpPost("complete/{rideId}")]
        public async Task<IActionResult> CompleteTrip(string rideId)
        {
            await _rideService.UpdateRideStatusAsync(rideId, "completed");
            return Ok(new { message = "Chuyến xe hoàn tất. Thu tiền!" });
        }

        // ==========================================
        // 4. API TEST KẾT NỐI FIREBASE
        // ==========================================
        [HttpGet("test-firebase-connection")]
        public async Task<IActionResult> TestFirebaseConnection()
        {
            try
            {
                var testData = new
                {
                    message = "Kết nối thành công rồi tml ơi!",
                    timestamp = DateTime.Now.ToString(),
                    check_by = "Backend Developer"
                };

                Console.WriteLine("🚀 Đang thử kết nối Firebase...");
                var success = await _firebaseService.TestConnectionAsync(testData);

                if (success)
                    return Ok(new { status = "Success", message = "Đã ghi xuống Firebase thành công!" });
                else
                    return BadRequest(new { status = "Failed", message = "Ghi thất bại" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { status = "Failed", error = ex.Message });
            }
        }
    }
}