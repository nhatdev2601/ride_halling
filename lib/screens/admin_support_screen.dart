import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  // ⚠️ API: Backend chưa có API GET ALL TICKETS. Tạm dùng Mock Data.
  final List<Map<String, String>> _mockTickets = [
    {
      'id': 'TKT001',
      'subject': 'Chưa nhận được thanh toán',
      'status': 'Open',
      'priority': 'High',
    },
    {
      'id': 'TKT002',
      'subject': 'Lỗi vị trí bản đồ',
      'status': 'Pending',
      'priority': 'Medium',
    },
    {
      'id': 'TKT003',
      'subject': 'Hoàn tiền chuyến đi bị hủy',
      'status': 'Resolved',
      'priority': 'High',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _mockTickets.length,
      itemBuilder: (context, index) {
        final ticket = _mockTickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(
              Icons.confirmation_number,
              color: _getStatusColor(ticket['status']!),
            ),
            title: Text(
              ticket['subject']!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'ID: ${ticket['id']} | Priority: ${ticket['priority']}',
            ),
            trailing: Chip(
              label: Text(
                ticket['status']!,
                style: const TextStyle(color: AppTheme.white),
              ),
              backgroundColor: _getStatusColor(ticket['status']!),
            ),
            onTap: () {
              // ✅ Navigate đến màn hình chi tiết Ticket (Gọi API /admin/tickets/{id})
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Xem chi tiết Ticket ${ticket['id']}')),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return AppTheme.error;
      case 'Pending':
        return AppTheme.blue;
      case 'Resolved':
        return AppTheme.primaryGreen;
      default:
        return AppTheme.grey;
    }
  }
}
