namespace api_ride.Models.DTOs
{
    public class PromotionDto
    {
        public string PromoCode { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string DiscountType { get; set; } = string.Empty; // "percentage" hoặc "fixed"
        public decimal DiscountValue { get; set; }
        public decimal MaxDiscount { get; set; }
        public decimal MinOrderValue { get; set; }
        public DateTime ValidTo { get; set; }

        // Thêm cái này để FE hiển thị cho đẹp
        // Ví dụ: "Giảm 50%" hoặc "Giảm 20k"
        public string DisplayText
        {
            get
            {
                if (DiscountType == "percentage")
                    return $"Giảm {DiscountValue}%";
                return $"Giảm {DiscountValue:N0}đ";
            }
        }
    }
}