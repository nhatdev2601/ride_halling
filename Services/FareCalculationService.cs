using api_ride.Models;
using api_ride.Models.DTOs;

namespace api_ride.Services
{
    public class FareCalculationService
    {
        private readonly ICassandraService _cassandraService;

        // Inject CassandraService để tra cứu mã KM
        public FareCalculationService(ICassandraService cassandraService)
        {
            _cassandraService = cassandraService;
        }

        private readonly Dictionary<string, FareRate> _fareRates = new()
        {
            { "bike", new FareRate 
                { 
                    BaseFare = 10000, 
                    PerKm = 3000, 
                    PerMinute = 500,
                    MinFare = 15000 
                } 
            },
            { "car", new FareRate 
                { 
                    BaseFare = 15000, 
                    PerKm = 5000, 
                    PerMinute = 1000,
                    MinFare = 25000 
                } 
            },
            { "business", new FareRate 
                { 
                    BaseFare = 25000, 
                    PerKm = 8000, 
                    PerMinute = 1500,
                    MinFare = 50000 
                } 
            }
        };

        public async Task<CalculateFareResponse> CalculateFareAsync(CalculateFareRequest request, Guid userId)
        {
            var rideId = Guid.NewGuid().ToString();
            var vehicleType = request.VehicleType.ToLower();

            if (!_fareRates.ContainsKey(vehicleType)) throw new ArgumentException($"Invalid vehicle type: {vehicleType}");

            var rate = _fareRates[vehicleType];

            // 1. Tính giá gốc
            decimal distance = (decimal)request.Distance;
            int estimatedDuration = request.Duration > 0 ? request.Duration : (int)(distance / 30m * 60m);

            decimal baseFare = (decimal)rate.BaseFare;
            decimal distanceFare = distance * (decimal)rate.PerKm;
            decimal timeFare = estimatedDuration * (decimal)rate.PerMinute;

            decimal surgeMultiplier = (decimal)GetSurgeMultiplier();
            decimal surgeFare = (baseFare + distanceFare + timeFare) * (surgeMultiplier - 1);

            decimal subtotal = baseFare + distanceFare + timeFare + surgeFare;
            if (subtotal < (decimal)rate.MinFare) subtotal = (decimal)rate.MinFare;

            // 2. Xử lý MÃ GIẢM GIÁ
            decimal discount = 0;
            Promotion? activePromo = null;
            bool userAlreadyUsed = false;

            if (!string.IsNullOrEmpty(request.PromoCode))
            {
                // Gọi DB check mã
                activePromo = await _cassandraService.GetPromotionByCodeAsync(request.PromoCode);

                if (activePromo != null)
                {
                    // Check user dùng chưa
                    userAlreadyUsed = await _cassandraService.CheckUserUsedPromoAsync(userId, request.PromoCode);

                    // Tính tiền giảm
                    var promoResult = CalculatePromoDiscount(activePromo, subtotal, userAlreadyUsed);
                    if (promoResult.IsValid)
                    {
                        discount = promoResult.DiscountAmount;
                    }
                }
            }

            decimal totalFare = Math.Round(subtotal - discount, 0);
            if (totalFare < 0) totalFare = 0;

            // 3. Tính list xe (AvailableVehicles) và áp dụng mã cho từng loại xe
            var availableVehicles = _fareRates.Select(kvp =>
            {
                var vRate = kvp.Value;
                decimal vSubtotal = (decimal)vRate.BaseFare + (distance * (decimal)vRate.PerKm) + (estimatedDuration * (decimal)vRate.PerMinute);
                vSubtotal *= surgeMultiplier;
                vSubtotal = Math.Max(vSubtotal, (decimal)vRate.MinFare);

                // Tính discount cho từng loại xe (vì điều kiện MinOrderValue có thể khác nhau)
                decimal vDiscount = 0;
                if (activePromo != null)
                {
                    var vResult = CalculatePromoDiscount(activePromo, vSubtotal, userAlreadyUsed);
                    if (vResult.IsValid) vDiscount = vResult.DiscountAmount;
                }

                return new VehicleOption
                {
                    VehicleType = kvp.Key,
                    DisplayName = GetDisplayName(kvp.Key),
                    BaseFare = vRate.BaseFare,
                    TotalFare = (double)Math.Round(vSubtotal - vDiscount, 0),
                    EstimatedArrival = new Random().Next(3, 10),
                    IconUrl = $"/assets/vehicles/{kvp.Key}.png"
                };
            }).ToList();

            return new CalculateFareResponse
            {
                RideId = rideId,
                Distance = (double)Math.Round(distance, 2),
                EstimatedDuration = estimatedDuration,
                BaseFare = (double)baseFare,
                DistanceFare = (double)distanceFare,
                TimeFare = (double)timeFare,
                SurgeFare = (double)surgeFare,
                Discount = (double)discount, // Trả về số tiền được giảm
                TotalFare = (double)totalFare, // Giá sau khi giảm
                AvailableVehicles = availableVehicles
            };
        }
        // Helper: Logic tính tiền giảm
        private PromoResult CalculatePromoDiscount(Promotion promo, decimal originalFare, bool userHasUsed)
        {
            var now = DateTime.UtcNow;
            if (promo.Status != "active" || now < promo.ValidFrom || now > promo.ValidTo)
                return new PromoResult { IsValid = false };

            if (promo.UsedCount >= promo.UsageLimit) return new PromoResult { IsValid = false };
            if (userHasUsed) return new PromoResult { IsValid = false };
            if (originalFare < promo.MinOrderValue) return new PromoResult { IsValid = false };

            decimal discount = 0;
            if (promo.DiscountType == "percentage")
            {
                discount = originalFare * (promo.DiscountValue / 100);
                if (discount > promo.MaxDiscount) discount = promo.MaxDiscount;
            }
            else // fixed
            {
                discount = promo.DiscountValue;
            }

            if (discount > originalFare) discount = originalFare;
            return new PromoResult { IsValid = true, DiscountAmount = discount };
        }
        // Surge pricing logic (gi? cao ?i?m)
        private double GetSurgeMultiplier()
        {
            //var currentHour = DateTime.Now.Hour;

            //// 7-9h sáng và 17-19h chi?u: x1.5
            //if ((currentHour >= 7 && currentHour <= 9) ||
            //    (currentHour >= 17 && currentHour <= 19))
            //{
            //    return 1.5;
            //}

            //// 22h-5h sáng: x1.3
            //if (currentHour >= 22 || currentHour <= 5)
            //{
            //    return 1.3;
            //}

            //return 1.0;
            return 1;
        }

        private string GetDisplayName(string vehicleType)
        {
            return vehicleType switch
            {
                "bike" => "Xe máy",
                "car" => "Xe 4 chổ",
                "business" => "Xe 7 chổ",
                _ => vehicleType
            };
        }
        private class PromoResult
        {
            public bool IsValid { get; set; }
            public decimal DiscountAmount { get; set; }
        }
    }

    public class FareRate
    {
        public double BaseFare { get; set; }
        public double PerKm { get; set; }
        public double PerMinute { get; set; }
        public double MinFare { get; set; }
    }
}