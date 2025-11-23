using api_ride.Models.DTOs;
using api_ride.Repositories;
using api_ride.Services;
using Microsoft.AspNetCore.Mvc;
using NGeoHash;
namespace api_ride.Controllers
{
        [ApiController]
        [Route("api/simulation")]
        public class SimulationController : ControllerBase
        {
            private readonly ICassandraService _cassandraService;
       
        private readonly IRideRepository _rideRepository;
        public SimulationController(ICassandraService cassandraService, IRideRepository rideRepository)
            {
                _cassandraService = cassandraService;
                 _rideRepository = rideRepository;
        }

            // 👇 API NÀY ĐỂ FLUTTER GỌI LÚC MỞ MAP
            [HttpPost("update-location-fake")]
            public async Task<IActionResult> UpdateDriverLocationFake([FromBody] Location location)
            {
                try
                {
                    // 1. ID cứng của thằng tài xế Khang (lấy từ script SQL tao đưa mày)
                    // Mày check lại trong DB xem đúng ID này chưa nhé
                    var driverId = Guid.Parse("99999999-9999-9999-9999-999999999999");

                    // 2. Tính Geohash mới dựa trên toạ độ Flutter gửi lên (Precision 6)
                    var newGeohash = GeoHash.Encode(location.Latitude, location.Longitude, 6);

                    // 3. Cập nhật bảng tìm kiếm (drivers_by_location)
                    // Logic Demo: Insert đè vào vị trí mới để tìm là thấy ngay.
                    // (Vị trí cũ ở geohash cũ vẫn còn rác, nhưng kệ nó, demo cho nhanh)
                    var querySearch = @"
                    INSERT INTO drivers_by_location (geohash, driver_id, latitude, longitude, is_available, rating, updated_at)
                    VALUES (?, ?, ?, ?, true, 5.0, toTimestamp(now()))";

                    // Lưu ý: Hàm ExecuteAsync của mày phải hỗ trợ truyền tham số dạng mảng object[]
                    await _cassandraService.ExecuteAsync(querySearch, new object[] {
                    newGeohash, driverId, location.Latitude, location.Longitude
                });

                    // 4. Cập nhật bảng thông tin chính (drivers)
                    // Để lúc click vào xem chi tiết thì thấy toạ độ mới
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
        // ... (code cũ giữ nguyên)

        // 1. Giả lập Tài xế đã đến điểm đón
        [HttpPost("pickup/{rideId}")]
        public async Task<IActionResult> DriverArrived(string rideId)
        {
            // Update status sang 'arrived'
            await _rideRepository.UpdateRideStatusAsync(rideId, "arrived");
            return Ok(new { message = "Tài xế đã đến nơi!" });
        }

        // 2. Giả lập Tài xế bắt đầu chạy
        [HttpPost("start/{rideId}")]
        public async Task<IActionResult> StartTrip(string rideId)
        {
            // Update status sang 'in_progress'
            await _rideRepository.UpdateRideStatusAsync(rideId, "in_progress");
            return Ok(new { message = "Chuyến xe bắt đầu!" });
        }

        // 3. Giả lập Hoàn thành chuyến xe
        [HttpPost("complete/{rideId}")]
        public async Task<IActionResult> CompleteTrip(string rideId)
        {
            // Update status sang 'completed'
            await _rideRepository.UpdateRideStatusAsync(rideId, "completed");
            return Ok(new { message = "Chuyến xe hoàn tất. Thu tiền!" });
        }
        // ...
    }
}

