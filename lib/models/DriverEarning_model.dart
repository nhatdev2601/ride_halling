class DriverEarning {
  final DateTime date;
  final double amount;

  DriverEarning({required this.date, required this.amount});

  factory DriverEarning.fromJson(Map<String, dynamic> json) {
    return DriverEarning(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
