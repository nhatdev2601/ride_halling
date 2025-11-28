import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

// Giả định AppConfig.baseUrl nếu bạn không có file config

// ==========================================================
// 1. MODELS (Mô hình Dữ liệu)
// ==========================================================

/// Model cho Dữ liệu Thống kê Tổng quan (Phù hợp với /dashboard/stats)
class AnalyticsSummary {
  final int totalUsers;
  final int totalDrivers;

  // Chi tiết trạng thái chuyến đi
  final int requesting;
  final int accepted;
  final int inProgress;
  final int completed;
  final int cancelled;
  final int totalActive; // = requesting + accepted + inProgress

  AnalyticsSummary({
    required this.totalUsers,
    required this.totalDrivers,
    required this.requesting,
    required this.accepted,
    required this.inProgress,
    required this.completed,
    required this.cancelled,
    required this.totalActive,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final systemStats = json['system_stats'] as Map<String, dynamic>;
    final rideStats = json.containsKey('ride_stats')
        ? json['ride_stats'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AnalyticsSummary(
      totalUsers: (systemStats['total_users'] ?? 0) as int,
      totalDrivers: (systemStats['total_drivers'] ?? 0) as int,

      requesting: (rideStats['requesting'] ?? 0) as int,
      accepted: (rideStats['accepted'] ?? 0) as int,
      inProgress: (rideStats['in_progress'] ?? 0) as int,
      completed: (rideStats['completed'] ?? 0) as int,
      cancelled: (rideStats['cancelled'] ?? 0) as int,
      totalActive: (rideStats['total_active'] ?? 0) as int,
    );
  }
}

/// Model cho Dữ liệu Xu hướng theo ngày (Line Chart - GIẢ LẬP)
class DailyStat {
  final DateTime date;
  final double dailyRevenue;
  final int totalRides;

  DailyStat({
    required this.date,
    required this.dailyRevenue,
    required this.totalRides,
  });
}

// ==========================================================
// 2. WIDGET & LOGIC
// ==========================================================

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsSummary? _summary;
  List<DailyStat> _dailyStats = []; // Dữ liệu cần giả lập
  bool _isLoading = false;

  static const String _baseUrl = '${AppConfig.baseUrl}/api/admin';
  static const Map<String, String> _headers = {
    'Authorization': 'Bearer YOUR_ADMIN_TOKEN',
  };

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
    _loadFakeDailyTrend(); // Load dữ liệu giả lập cho biểu đồ đường
  }

  // --- API Calls ---

  Future<void> _loadAllAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    await _loadSummaryData();
    // Không gọi _loadDailyTrend() vì endpoint này không có trong code C# của bạn.

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSummaryData() async {
    try {
      // Gọi endpoint đã được cung cấp trong backend C#: /api/admin/dashboard/stats
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/stats'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final summary = AnalyticsSummary.fromJson(jsonDecode(response.body));
        setState(() {
          _summary = summary;
        });
        _showSnackBar('Dashboard stats loaded successfully.');
      } else {
        throw Exception(
          'Failed to load dashboard stats. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('Error loading dashboard summary: $e');
    }
  }

  // Hàm giả lập dữ liệu xu hướng cho Line Chart
  void _loadFakeDailyTrend() {
    setState(() {
      // Giả lập 7 ngày gần nhất
      _dailyStats = [
        DailyStat(
          date: DateTime(2025, 11, 21),
          dailyRevenue: 1200,
          totalRides: 45,
        ),
        DailyStat(
          date: DateTime(2025, 11, 22),
          dailyRevenue: 1550,
          totalRides: 58,
        ),
        DailyStat(
          date: DateTime(2025, 11, 23),
          dailyRevenue: 980,
          totalRides: 32,
        ),
        DailyStat(
          date: DateTime(2025, 11, 24),
          dailyRevenue: 1800,
          totalRides: 65,
        ),
        DailyStat(
          date: DateTime(2025, 11, 25),
          dailyRevenue: 1700,
          totalRides: 60,
        ),
        DailyStat(
          date: DateTime(2025, 11, 26),
          dailyRevenue: 2100,
          totalRides: 75,
        ),
        DailyStat(
          date: DateTime(2025, 11, 27),
          dailyRevenue: 2500,
          totalRides: 88,
        ),
      ];
    });
  }

  // --- Chart & Utility Logic ---

  Map<String, int> _getRideStatusCountsFromSummary() {
    if (_summary == null) return {};
    return {
      'requesting': _summary!.requesting,
      'accepted': _summary!.accepted,
      'in_progress': _summary!.inProgress,
      'completed': _summary!.completed,
      'cancelled': _summary!.cancelled,
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requesting':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Build Widgets ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_summary != null) ...[
                  _buildSummaryCards(_summary!),
                  const Divider(height: 30),
                ],

                // Biểu đồ Xu hướng Doanh thu (Dữ liệu giả lập)
                _buildRevenueLineChart(),
                const Divider(height: 30),

                // Biểu đồ Phân bổ Trạng thái chuyến đi
                _buildPieChartSection(),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(AnalyticsSummary summary) {
    // Danh sách các chỉ số cần hiển thị
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Số người dừng',
        'value': summary.totalUsers.toString(),
        'icon': Icons.people_alt,
        'color': Colors.blueGrey,
      },
      {
        'title': 'số tài xế',
        'value': summary.totalDrivers.toString(),
        'icon': Icons.local_taxi,
        'color': Colors.blue,
      },
      {
        'title': 'Chuyến xe đang chạy',
        'value': summary.totalActive.toString(),
        'icon': Icons.flash_on,
        'color': Colors.orange,
      },
      {
        'title': 'Chuyến xe hoàn tất',
        'value': summary.completed.toString(),
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          stat['title'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
          stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart() {
    if (_dailyStats.isEmpty) {
      return const Center(
        child: Text('No daily trend data available for charting.'),
      );
    }

    final spots = _dailyStats.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.dailyRevenue / 100,
      ); // Chia nhỏ để scale tốt hơn
    }).toList();

    final days = _dailyStats
        .map((e) => '${e.date.month}/${e.date.day}')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doanh thu (7 ngày qua)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: LineChart(
              LineChartData(
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.pink,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.pink.withOpacity(0.3),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value * 100).toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ); // Scale lại giá trị Y
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection() {
    final statusCounts = _getRideStatusCountsFromSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Status Distribution (Total Rides)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: statusCounts.values.every((e) => e == 0)
              ? const Center(child: Text('No ride data available'))
              : Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 4,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: statusCounts.entries.map((entry) {
                            return PieChartSectionData(
                              color: _getStatusColor(entry.key),
                              value: entry.value.toDouble(),
                              title: '${entry.value}',
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Legend
                    Expanded(
                      flex: 3,
                      child: ListView(
                        children: statusCounts.entries.map((entry) {
                          if (entry.value == 0)
                            return const SizedBox.shrink(); // Ẩn trạng thái có count bằng 0
                          return ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              color: _getStatusColor(entry.key),
                            ),
                            title: Text(
                              '${entry.key} (${entry.value})',
                              style: const TextStyle(fontSize: 12),
                            ),
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
