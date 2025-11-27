class Promotion {
  final String promoCode;
  final String description;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final String displayText; // Cái chuỗi "Giảm 50%" hoặc "Giảm 20k"

  Promotion({
    required this.promoCode,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.displayText,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      promoCode: json['promoCode'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? '',
      discountValue: (json['discountValue'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num).toDouble(),
      displayText: json['displayText'] ?? '',
    );
  }
}