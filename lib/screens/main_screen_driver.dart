import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart'; // ✅ Import AuthService (singleton)
import 'home_screen_driver.dart'; // ✅ Trang chủ cho tài xế (bản đồ nhận chuyến)
import 'ongoing_trips_screen.dart'; // ✅ Màn hình chuyến đi đang diễn ra
import 'earnings_screen.dart'; // ✅ Màn hình thu nhập
import 'driver_profile_screen.dart'; // ✅ Tách riêng ProfileScreen để clean code
import 'login_screen.dart'; // ✅ Màn hình đăng nhập
import '../models/auth_models.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenDriver(), // ✅ Trang chủ cho tài xế
    const OngoingTripsScreen(), // Chuyến đi
    const EarningsScreen(), // Thu nhập
    const DriverProfileScreen(), // Tài khoản
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
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Chuyến đi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Thu nhập',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

// ✅ Tách riêng DriverProfileScreen thành file riêng (driver_profile_screen.dart)
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final AuthService _authService = AuthService(); // ✅ Singleton AuthService
  bool _isLoading = false; // ✅ Loading state cho logout
  UserDto? _user; // ✅ Lưu user từ AuthService

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // ✅ Load profile khi init
  }

  // ✅ Load user profile từ AuthService
  Future<void> _loadUserProfile() async {
    try {
      _user = await _authService.getCurrentUser(); // Gọi API /me hoặc /profile
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _user?.fullName.substring(0, 2).toUpperCase() ??
                          'TX', // ✅ Từ UserDto
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
                          _user?.fullName ?? 'Vo Truong Nhat', // ✅ Từ UserDto
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? 'vonhut@email.com', // ✅ Từ UserDto
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.phone ??
                              '0901234567', // ✅ Từ UserDto (phoneNumber)
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ✅ Thông tin xe (giả sử từ profile API, hoặc hardcoded tạm)
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                    onPressed: () async {
                      // ✅ Navigate đến edit profile screen hoặc show dialog
                      final updatedUser = await _showEditProfileDialog(context);
                      if (updatedUser != null) {
                        setState(() => _user = updatedUser);
                      }
                    },
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
                    () => _showEditProfileDialog(context), // ✅ Gọi edit
                  ),
                  _buildMenuItem(
                    Icons.directions_car_outlined,
                    'Thông tin xe',
                    () {
                      // ✅ Navigate đến screen chỉnh sửa xe (tạo sau)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng sắp có')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    Icons.payment_outlined,
                    'Phương thức thanh toán',
                    () {
                      // ✅ Navigate đến EarningsScreen (hoặc PaymentScreen riêng)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EarningsScreen(),
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
                  _buildMenuItem(Icons.help_outline, 'Trợ giúp & Hỗ trợ', () {
                    // ✅ Navigate đến support screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hỗ trợ sắp có')),
                    );
                  }),
                  _buildMenuItem(Icons.star_outline, 'Đánh giá ứng dụng', () {
                    // ✅ Mở store review
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đánh giá sắp có')),
                    );
                  }),
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
                  _buildMenuItem(Icons.notifications_outlined, 'Thông báo', () {
                    // ✅ Navigate đến notification screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thông báo sắp có')),
                    );
                  }),
                  _buildMenuItem(Icons.language_outlined, 'Ngôn ngữ', () {}),
                  _buildMenuItem(Icons.security_outlined, 'Bảo mật', () {
                    // ✅ Navigate đến change password
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ChangePasswordScreen(), // Tạo screen riêng
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => _showLogoutDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
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

  // ✅ Dialog chỉnh sửa profile (placeholder, tích hợp UpdateProfileRequest sau)
  Future<UserDto?> _showEditProfileDialog(BuildContext context) async {
    // Giả sử show dialog với form edit
    return showDialog<UserDto?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa profile'),
        content: const Text('Form edit sẽ ở đây'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Gọi _authService.updateProfile(request)
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
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
              Navigator.pop(context);
              await _handleLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  // ✅ Xử lý logout với AuthService
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      await _authService.logout(); // ✅ Gọi API logout & clear tokens

      if (!mounted) return;

      // ✅ Chuyển về login và clear stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng xuất thành công'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng xuất: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

// ✅ Placeholder cho ChangePasswordScreen (tạo file riêng)
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: const Center(child: Text('Form đổi mật khẩu sẽ ở đây')),
    );
  }
}
