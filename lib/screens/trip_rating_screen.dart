import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'main_screen.dart'; //  Đổi sang MainScreen

class TripRatingScreen extends StatefulWidget {
  final Trip trip;

  const TripRatingScreen({super.key, required this.trip});

  @override
  State<TripRatingScreen> createState() => _TripRatingScreenState();
}

class _TripRatingScreenState extends State<TripRatingScreen> {
  double _rating = 5.0;
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> _quickFeedbacks = [
    'Tài xế lịch sự',
    'Đúng giờ',
    'Lái xe an toàn',
    'Xe sạch sẽ',
    'Thái độ tốt',
    'Nhiệt tình',
  ];
  final Set<String> _selectedFeedbacks = {};

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitRating() {
    // Xử lý gửi đánh giá
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ), //  Quay về MainScreen
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Đánh giá chuyến đi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // For symmetry
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 60,
                        color: AppTheme.success,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Chuyến đi hoàn thành!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Trip summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: AppTheme.primaryGreen,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.trip.pickupAddress,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.square,
                                color: AppTheme.error,
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.trip.destinationAddress,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tổng cước:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${widget.trip.fare.toInt()}đ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Driver info
                    if (widget.trip.driver != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.lightGrey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.lightGrey,
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.trip.driver!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.trip.driver!.vehicleModel} - ${widget.trip.driver!.vehiclePlate}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Rating section
                      const Text(
                        'Đánh giá tài xế',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      RatingBar.builder(
                        initialRating: _rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, _) =>
                            const Icon(Icons.star, color: AppTheme.warning),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _rating = rating;
                          });
                        },
                        itemSize: 40,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _getRatingText(_rating),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryGreen,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick feedback tags
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Đánh giá nhanh:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickFeedbacks.map((feedback) {
                          final isSelected = _selectedFeedbacks.contains(
                            feedback,
                          );
                          return FilterChip(
                            label: Text(feedback),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFeedbacks.add(feedback);
                                } else {
                                  _selectedFeedbacks.remove(feedback);
                                }
                              });
                            },
                            backgroundColor: AppTheme.lightGrey,
                            selectedColor: AppTheme.primaryGreen.withOpacity(
                              0.2,
                            ),
                            checkmarkColor: AppTheme.primaryGreen,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.grey,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Feedback text field
                      TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Chia sẻ thêm về trải nghiệm của bạn...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Gửi đánh giá',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(fontSize: 16, color: AppTheme.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Xuất sắc';
    if (rating >= 4.0) return 'Tốt';
    if (rating >= 3.0) return 'Bình thường';
    if (rating >= 2.0) return 'Chưa tốt';
    return 'Kém';
  }
}
