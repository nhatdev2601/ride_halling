// ✅ EarningsScreen (lib/screens/earnings_screen.dart)
// Màn hình thu nhập: Summary + Lịch sử (tích hợp EarningsService)

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/EarningsService.dart';
import '../models/ride_models.dart';
import '../models/EarningsSummary_model.dart';
import '../models/DriverEarning_model.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsService _earningsService = EarningsService();
  EarningsSummary _summary = EarningsSummary.empty();
  bool _isLoading = true;
  DateTime _fromDate = DateTime.now().subtract(
    const Duration(days: 30),
  ); // 30 ngày qua
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  // ✅ Load thu nhập
  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      _summary = await _earningsService.getEarnings(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải thu nhập: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        title: const Text(
          'Thu nhập',
          style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _loadEarnings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ Thống kê tổng quan
                  Container(
                    color: AppTheme.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Tổng thu nhập',
                          style: TextStyle(fontSize: 14, color: AppTheme.grey),
                        ),
                        Text(
                          '${_summary.totalEarnings.toStringAsFixed(0)}đ',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              'Tháng này',
                              '${_summary.thisMonthEarnings.toStringAsFixed(0)}đ',
                            ),
                            _buildStatCard(
                              'Tổng chuyến',
                              '${_summary.history.length} chuyến',
                            ), // Giả sử history là số chuyến
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Lịch sử thu nhập
                  Container(
                    color: AppTheme.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Lịch sử',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.black,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Chọn date range (sử dụng showDateRangePicker)
                                  final range = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDateRange: DateTimeRange(
                                      start: _fromDate,
                                      end: _toDate,
                                    ),
                                  );
                                  if (range != null) {
                                    setState(() {
                                      _fromDate = range.start;
                                      _toDate = range.end;
                                    });
                                    _loadEarnings();
                                  }
                                },
                                child: const Text('Lọc ngày'),
                              ),
                            ],
                          ),
                        ),
                        if (_summary.history.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('Chưa có lịch sử thu nhập'),
                            ),
                          )
                        else
                          ..._summary.history.map(
                            (earning) => _buildEarningItem(earning),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.grey)),
      ],
    );
  }

  Widget _buildEarningItem(DriverEarning earning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lightGrey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${earning.date.day}/${earning.date.month}/${earning.date.year}',
          ),
          Text('${earning.amount.toStringAsFixed(0)}đ'),
        ],
      ),
    );
  }
}
