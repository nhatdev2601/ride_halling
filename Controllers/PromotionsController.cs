using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using api_ride.Models.DTOs;
using api_ride.Services;
using System.Security.Claims;

namespace api_ride.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Phải đăng nhập mới xem được mã
    public class PromotionsController : ControllerBase
    {
        private readonly ICassandraService _cassandraService;
        private readonly ILogger<PromotionsController> _logger;

        public PromotionsController(ICassandraService cassandraService, ILogger<PromotionsController> logger)
        {
            _cassandraService = cassandraService;
            _logger = logger;
        }

        // 1. Lấy danh sách khuyến mãi đang Active (Hiển thị lên list)
        [HttpGet]
        public async Task<ActionResult<List<PromotionDto>>> GetActivePromotions()
        {
            try
            {
                var promos = await _cassandraService.GetActivePromotionsAsync();

                // Map sang DTO
                var result = promos.Select(p => new PromotionDto
                {
                    PromoCode = p.PromoCode,
                    Description = p.Description,
                    DiscountType = p.DiscountType,
                    DiscountValue = p.DiscountValue,
                    MaxDiscount = p.MaxDiscount,
                    MinOrderValue = p.MinOrderValue,
                    ValidTo = p.ValidTo
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting promotions");
                return StatusCode(500, new { error = "Internal server error" });
            }
        }

        // 2. Check xem 1 mã cụ thể có hợp lệ với User này không (Khi user nhập tay)
        [HttpGet("check/{code}")]
        public async Task<IActionResult> CheckPromotion(string code)
        {
            try
            {
                var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdString)) return Unauthorized();
                Guid.TryParse(userIdString, out var userId);

                var promo = await _cassandraService.GetPromotionByCodeAsync(code);

                if (promo == null)
                    return NotFound(new { valid = false, message = "Mã không tồn tại" });

                var now = DateTime.UtcNow;

                // Check cơ bản
                if (promo.Status != "active")
                    return BadRequest(new { valid = false, message = "Mã này đã bị vô hiệu hóa" });

                if (now < promo.ValidFrom || now > promo.ValidTo)
                    return BadRequest(new { valid = false, message = "Mã đã hết hạn sử dụng" });

                if (promo.UsedCount >= promo.UsageLimit)
                    return BadRequest(new { valid = false, message = "Mã đã hết lượt sử dụng" });

                // Check user dùng chưa
                bool hasUsed = await _cassandraService.CheckUserUsedPromoAsync(userId, code);
                if (hasUsed)
                    return BadRequest(new { valid = false, message = "Bạn đã sử dụng mã này rồi" });

                // Trả về OK nếu ngon
                return Ok(new
                {
                    valid = true,
                    message = "Mã hợp lệ",
                    details = new PromotionDto
                    {
                        PromoCode = promo.PromoCode,
                        Description = promo.Description,
                        DiscountType = promo.DiscountType,
                        DiscountValue = promo.DiscountValue,
                        MaxDiscount = promo.MaxDiscount,
                        MinOrderValue = promo.MinOrderValue,
                        ValidTo = promo.ValidTo
                    }
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }
    }
}