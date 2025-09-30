import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LocationInput extends StatefulWidget {
  final Function(String) onPickupChanged;
  final Function(String) onDestinationChanged;

  const LocationInput({
    super.key,
    required this.onPickupChanged,
    required this.onDestinationChanged,
  });

  @override
  State<LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<LocationInput> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đi đâu?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 16),

          // Điểm đi
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pickupController,
                  onChanged: widget.onPickupChanged,
                  decoration: InputDecoration(
                    hintText: 'Điểm đi',
                    hintStyle: TextStyle(color: AppTheme.grey.withOpacity(0.7)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: AppTheme.lightGrey.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Đường kẻ nối
          Container(
            margin: const EdgeInsets.only(left: 6),
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  width: 1,
                  height: 4,
                  color: AppTheme.grey.withOpacity(0.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Điểm đến
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  onChanged: widget.onDestinationChanged,
                  decoration: InputDecoration(
                    hintText: 'Điểm đến',
                    hintStyle: TextStyle(color: AppTheme.grey.withOpacity(0.7)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: AppTheme.lightGrey.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Các lựa chọn nhanh
          Row(
            children: [
              _buildQuickOption(Icons.home, 'Nhà'),
              const SizedBox(width: 12),
              _buildQuickOption(Icons.work, 'Văn phòng'),
              const SizedBox(width: 12),
              _buildQuickOption(Icons.history, 'Gần đây'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
          ],
        ),
      ),
    );
  }
}
