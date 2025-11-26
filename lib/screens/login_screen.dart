import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart'; // ✅ Thêm import AuthService
import '../models/auth_models.dart'; // ✅ Thêm import AuthModels
import 'register_screen.dart';
import 'main_screen.dart'; // ✅ MainScreen cho passenger
import 'main_screen_driver.dart'; // ✅ DriverMainScreen cho driver

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  final _emailController = TextEditingController(text: "thao@gmail.com");
  final _passwordController = TextEditingController(text: "123456");
  final AuthService _authService = AuthService(); // ✅ Thêm AuthService

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // ✅ Kiểm tra validation trước
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Gọi API login thật
      final response = await _authService.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;

      // ✅ Nếu login thành công, kiểm tra role và chuyển màn hình tương ứng
      Widget nextScreen;
      String welcomeMessage;
      if (response.user.role == 'driver') {
        nextScreen = const DriverMainScreen();
        welcomeMessage =
            'Đăng nhập thành công! Xin chào ${response.user.fullName} - Ứng dụng tài xế';
      } else {
        nextScreen = const MainScreen();
        welcomeMessage =
            'Đăng nhập thành công! Xin chào ${response.user.fullName} - Ứng dụng khách hàng';
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );

      // ✅ Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(welcomeMessage),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // ✅ Hiển thị lỗi chi tiết
      String errorMessage = 'Đăng nhập thất bại';

      if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'Email hoặc mật khẩu không đúng';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        errorMessage =
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Kết nối quá lâu. Vui lòng thử lại.';
      } else {
        errorMessage = 'Lỗi: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập email để nhận link đặt lại mật khẩu:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link đặt lại mật khẩu đã được gửi!'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Logo and Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 50,
                            color: AppTheme.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'RideApp',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Chào mừng trở lại!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Login Form
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.primaryGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.grey.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.primaryGreen,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.grey.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (value.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            // Remember Me & Forgot Password
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryGreen,
                                ),
                                const Text(
                                  'Ghi nhớ đăng nhập',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _forgotPassword,
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: AppTheme.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Đăng nhập',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppTheme.grey.withOpacity(0.3),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Hoặc',
                                    style: TextStyle(
                                      color: AppTheme.grey.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppTheme.grey.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Social Login Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Google login
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đăng nhập với Google'),
                                          backgroundColor: AppTheme.info,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.g_mobiledata,
                                      color: AppTheme.error,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Google',
                                      style: TextStyle(
                                        color: AppTheme.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.grey.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Facebook login
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đăng nhập với Facebook',
                                          ),
                                          backgroundColor: AppTheme.info,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.facebook,
                                      color: Color(0xFF1877F2),
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Facebook',
                                      style: TextStyle(
                                        color: AppTheme.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.grey.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Expanded(child: SizedBox(height: 20)),

                  // Register Link
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(
                            color: AppTheme.grey.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
