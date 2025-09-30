import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomBookButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BottomBookButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Các dịch vụ nhanh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceItem(
                Icons.motorcycle,
                'Bike',
                AppTheme.primaryGreen,
              ),
              _buildServiceItem(Icons.directions_car, 'Car', AppTheme.info),
              _buildServiceItem(
                Icons.local_shipping,
                'Delivery',
                AppTheme.warning,
              ),
              _buildServiceItem(Icons.restaurant, 'Food', AppTheme.error),
            ],
          ),

          const SizedBox(height: 20),

          // Nút đặt xe chính
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Đặt xe ngay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
