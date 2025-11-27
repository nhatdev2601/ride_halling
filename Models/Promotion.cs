namespace api_ride.Models
{
    public class Promotion
    {
        public string PromoCode { get; set; }
        public string Description { get; set; }
        public string DiscountType { get; set; } // "percentage" hoặc "fixed"
        public decimal DiscountValue { get; set; } // Ví dụ: 50 (là 50%) hoặc 20000 (là 20k)
        public decimal MaxDiscount { get; set; }   // Giảm tối đa bao nhiêu (để tránh lỗ vốn khi giảm %)
        public decimal MinOrderValue { get; set; } // Đơn tối thiểu
        public string Status { get; set; }         // "active", "expired"
        public int UsageLimit { get; set; }        // Tổng số lượt dùng toàn hệ thống
        public int UsedCount { get; set; }         // Đã dùng bao nhiêu
        public DateTime ValidFrom { get; set; }
        public DateTime ValidTo { get; set; }
    }
}