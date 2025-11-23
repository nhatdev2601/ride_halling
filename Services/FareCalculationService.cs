using api_ride.Models.DTOs;

namespace api_ride.Services
{
    public class FareCalculationService
    {
        
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

        public CalculateFareResponse CalculateFare(CalculateFareRequest request)
        {
            var rideId = Guid.NewGuid().ToString();
            var vehicleType = request.VehicleType.ToLower();

            if (!_fareRates.ContainsKey(vehicleType))
            {
                throw new ArgumentException($"Invalid vehicle type: {vehicleType}");
            }

            var rate = _fareRates[vehicleType];

            // Chuyển sang decimal để tính tiền cho chuẩn
            decimal distance = (decimal)request.Distance;

            // Ước tính thời gian (giả sử tốc độ 30km/h)
            // Nếu request có gửi duration lên thì nên dùng cái đó: request.Duration
            int estimatedDuration = (int)(distance / 30m * 60m);

            // Tính giá cơ bản
            decimal baseFare = (decimal)rate.BaseFare;
            decimal distanceFare = distance * (decimal)rate.PerKm;
            decimal timeFare = estimatedDuration * (decimal)rate.PerMinute;

            // Surge pricing
            decimal surgeMultiplier = (decimal)GetSurgeMultiplier();
            decimal surgeFare = (baseFare + distanceFare + timeFare) * (surgeMultiplier - 1);

            // Tổng
            decimal subtotal = baseFare + distanceFare + timeFare + surgeFare;

            // Giá tối thiểu
            if (subtotal < (decimal)rate.MinFare)
            {
                subtotal = (decimal)rate.MinFare;
            }

            decimal discount = 0.0m;
            decimal totalFare = Math.Round(subtotal - discount, 0);

            // Tính list xe (AvailableVehicles)
            var availableVehicles = _fareRates.Select(kvp =>
            {
                var vRate = kvp.Value;
                decimal vSubtotal = (decimal)vRate.BaseFare +
                                   (distance * (decimal)vRate.PerKm) +
                                   (estimatedDuration * (decimal)vRate.PerMinute);

                vSubtotal *= surgeMultiplier;
                vSubtotal = Math.Max(vSubtotal, (decimal)vRate.MinFare);

                return new VehicleOption
                {
                    VehicleType = kvp.Key,
                    DisplayName = GetDisplayName(kvp.Key), // Coi chừng lỗi font tiếng Việt ở đây
                    BaseFare = vRate.BaseFare, // Model trả về double thì ép kiểu lại
                    TotalFare = (double)Math.Round(vSubtotal, 0),
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
                SurgeFare = (double)surgeFare, // Sẽ hết bị lỗi 4800.000001
                Discount = (double)discount,
                TotalFare = (double)totalFare,
                AvailableVehicles = availableVehicles
            };
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
    }

    public class FareRate
    {
        public double BaseFare { get; set; }
        public double PerKm { get; set; }
        public double PerMinute { get; set; }
        public double MinFare { get; set; }
    }
}