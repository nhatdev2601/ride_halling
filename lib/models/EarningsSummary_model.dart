import 'DriverEarning_model.dart';

class EarningsSummary {
  final double totalEarnings;
  final double thisMonthEarnings;
  final List<DriverEarning> history;

  EarningsSummary({
    required this.totalEarnings,
    required this.thisMonthEarnings,
    required this.history,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      thisMonthEarnings: (json['thisMonthEarnings'] as num?)?.toDouble() ?? 0.0,
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => DriverEarning.fromJson(e))
              .toList() ??
          [],
    );
  }

  factory EarningsSummary.empty() =>
      EarningsSummary(totalEarnings: 0.0, thisMonthEarnings: 0.0, history: []);
}
