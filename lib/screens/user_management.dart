import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/config.dart'; // Giả định bạn có file config này

// 1. Model User (dựa trên DTO từ backend JSON response)
class User {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String userType;
  String status; // Non-final để có thể update
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.status,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'].toString(), // Giả sử backend trả về 'user_id'
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      userType: json['user_type'] ?? '',
      status: (json['status'] ?? 'unknown').toString().toLowerCase(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// 2. Định nghĩa DTO cho request (tương ứng với UpdateUserStatusRequest ở C#)
class UpdateUserStatusRequest {
  final String status;

  UpdateUserStatusRequest({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = false;
  User? _selectedUser;

  // Base URL của API (thay đổi theo server của bạn)
  // Giả định AppConfig.baseUrl là 'http://your-server:port'
  static const String _baseUrl = '${AppConfig.baseUrl}/api/admin';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // --- UTILITY METHODS ---

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
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

  // --- API CALLS ---

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users'),
        headers: {
          // THAY THẾ 'YOUR_ADMIN_TOKEN' BẰNG TOKEN THỰC TẾ CỦA BẠN
          'Authorization': 'Bearer YOUR_ADMIN_TOKEN',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        // Giả sử API trả về list users trong key 'users'
        final List<dynamic> usersData = responseData['users'] ?? [];
        setState(() {
          _users = usersData.map((json) => User.fromJson(json)).toList();
        });
      } else {
        _showSnackBar('Failed to load users (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Error loading users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserByEmail(String email) async {
    setState(() {
      _selectedUser = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/by-email?email=$email'),
        headers: {'Authorization': 'Bearer YOUR_ADMIN_TOKEN'},
      );
      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        setState(() {
          _selectedUser = user;
        });
        _showSnackBar('User found: ${user.fullName}');
      } else {
        _showSnackBar('User not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _getUserById(String id) async {
    setState(() {
      _selectedUser = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$id'),
        headers: {'Authorization': 'Bearer YOUR_ADMIN_TOKEN'},
      );
      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        setState(() {
          _selectedUser = user;
        });
        _showSnackBar('User found: ${user.fullName}');
      } else {
        _showSnackBar('User not found (Status: ${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    // Backend chỉ chấp nhận: 'active', 'suspended', 'banned'
    final normalizedStatus = status.toLowerCase();

    try {
      final requestBody = UpdateUserStatusRequest(status: normalizedStatus);

      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_ADMIN_TOKEN',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Cập nhật trong list
          final index = _users.indexWhere((u) => u.id == userId);
          if (index != -1) {
            // Tạo User mới (hoặc dùng copyWith nếu User có)
            _users[index] = User(
              id: _users[index].id,
              fullName: _users[index].fullName,
              email: _users[index].email,
              phoneNumber: _users[index].phoneNumber,
              userType: _users[index].userType,
              status: normalizedStatus, // Cập nhật trạng thái
              createdAt: _users[index].createdAt,
            );
          }
          // Cập nhật selected user nếu khớp
          if (_selectedUser?.id == userId) {
            _selectedUser = User(
              id: _selectedUser!.id,
              fullName: _selectedUser!.fullName,
              email: _selectedUser!.email,
              phoneNumber: _selectedUser!.phoneNumber,
              userType: _selectedUser!.userType,
              status: normalizedStatus, // Cập nhật trạng thái
              createdAt: _selectedUser!.createdAt,
            );
          }
        });
        _showSnackBar('Status updated to $normalizedStatus');
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(
          'Failed to update status: ${error['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tìm user by email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Search User by Email',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _getUserByEmail(value.trim()),
            ),
            const SizedBox(height: 10),
            // Tìm user by ID
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'Search User by ID (UUID)',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _getUserById(value.trim()),
            ),
            const SizedBox(height: 20),

            // --- Hiển thị Selected User Info ---
            if (_selectedUser != null) ...[
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected User:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('ID: ${_selectedUser!.id}'),
                      Text('Full Name: ${_selectedUser!.fullName}'),
                      Text('Email: ${_selectedUser!.email}'),
                      Text('Phone: ${_selectedUser!.phoneNumber}'),
                      Text('Type: ${_selectedUser!.userType}'),
                      Text(
                        'Status: ${_selectedUser!.status}',
                        style: TextStyle(
                          color: _getStatusColor(_selectedUser!.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Created: ${_selectedUser!.createdAt.toLocal().toString().split(' ')[0]}',
                      ),
                      const SizedBox(height: 10),
                      // Nút update status for selected (Đã loại bỏ Row thừa)
                      Wrap(
                        // <--- Bắt đầu từ Wrap
                        spacing: 8.0, // Khoảng cách ngang giữa các nút
                        runSpacing: 8.0, // Khoảng cách dọc khi xuống dòng
                        children: [
                          // Nút 1: Activate
                          ElevatedButton(
                            onPressed: () =>
                                _updateUserStatus(_selectedUser!.id, 'active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Activate',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),

                          // Nút 2: Suspend
                          ElevatedButton(
                            onPressed: () => _updateUserStatus(
                              _selectedUser!.id,
                              'suspended',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Suspend',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),

                          // Nút 3: Ban
                          ElevatedButton(
                            onPressed: () =>
                                _updateUserStatus(_selectedUser!.id, 'banned'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Ban',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ), // <--- Kết thúc Wrap
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],

            // --- Hiển thị Full List Users ---
            Text(
              'All Users (Total: ${_users.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                  ? const Center(child: Text('No users available'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isSelected = _selectedUser?.id == user.id;
                        return Card(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : null,
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                              });
                            },
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(user.status),
                              child: Text(
                                user.userType[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(user.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Text(
                                  'Type: ${user.userType} | Status: ${user.status}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(user.status),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _updateUserStatus(user.id, 'active'),
                                  icon: Icon(
                                    Icons.check_circle,
                                    color: _getStatusColor('active'),
                                  ),
                                  tooltip: 'Activate',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _updateUserStatus(user.id, 'suspended'),
                                  icon: Icon(
                                    Icons.pause_circle_filled,
                                    color: _getStatusColor('suspended'),
                                  ),
                                  tooltip: 'Suspend',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _updateUserStatus(user.id, 'banned'),
                                  icon: Icon(
                                    Icons.block,
                                    color: _getStatusColor('banned'),
                                  ),
                                  tooltip: 'Ban',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
