import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart'; // ✅ Thêm import AuthService
import 'home_screen.dart';
import 'trip_history_screen.dart';
import 'payment_screen.dart';
import 'login_screen.dart'; // ✅ Thêm import LoginScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TripHistoryScreen(),
    const PaymentScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.grey,
        backgroundColor: AppTheme.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Thanh toán',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService(); // ✅ Thêm AuthService
  bool _isLoading = false; // ✅ Thêm loading state

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser; // ✅ Lấy thông tin user

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'Tài khoản',
          style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              color: AppTheme.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      user?.fullName.substring(0, 2).toUpperCase() ??
                          'NV', // ✅ Lấy từ user
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Vo Truong Nhat', //  Lấy từ user
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'vonhut@email.com', //  Lấy từ user
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? '0901234567', //  Lấy từ user
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account section
            Container(
              color: AppTheme.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.person_outline,
                    'Thông tin cá nhân',
                    () {},
                  ),
                  _buildMenuItem(
                    Icons.location_on_outlined,
                    'Địa chỉ đã lưu',
                    () {},
                  ),
                  _buildMenuItem(
                    Icons.payment_outlined,
                    'Phương thức thanh toán',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Support section
            Container(
              color: AppTheme.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.help_outline,
                    'Trợ giúp & Hỗ trợ',
                    () {},
                  ),
                  _buildMenuItem(
                    Icons.star_outline,
                    'Đánh giá ứng dụng',
                    () {},
                  ),
                  _buildMenuItem(Icons.info_outline, 'Về chúng tôi', () {}),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings section
            Container(
              color: AppTheme.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.notifications_outlined,
                    'Thông báo',
                    () {},
                  ),
                  _buildMenuItem(Icons.language_outlined, 'Ngôn ngữ', () {}),
                  _buildMenuItem(Icons.security_outlined, 'Bảo mật', () {}),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => _showLogoutDialog(context), // ✅ Disable khi loading
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading // ✅ Hiển thị loading khi đang logout
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.error,
                        ),
                      )
                    : const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.lightGrey, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // ✅ Đóng dialog
              await _handleLogout(); // ✅ Gọi hàm logout
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  // ✅ Hàm xử lý logout
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      // ✅ Gọi API logout
      await _authService.logout();

      if (!mounted) return;

      // ✅ Chuyển về màn hình login và xóa toàn bộ stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // ✅ Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng xuất thành công'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // ✅ Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng xuất: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
