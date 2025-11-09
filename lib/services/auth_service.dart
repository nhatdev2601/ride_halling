import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthService {
  // Đổi URL này thành URL backend của bạn
  static const String baseUrl = 'http://10.0.2.2:5267/api/Auth';

  String? _token;
  String? _refreshToken;
  UserDto? _currentUser;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  UserDto? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Lưu token vào SharedPreferences
  Future<void> _saveTokens(String token, String refreshToken) async {
    _token = token;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', refreshToken);
  }

  // Lưu user info
  Future<void> _saveUser(UserDto user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  // Load tokens từ SharedPreferences
  Future<void> loadSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');

    final userJson = prefs.getString('user');
    if (userJson != null) {
      _currentUser = UserDto.fromJson(jsonDecode(userJson));
    }
  }

  // Clear tokens
  Future<void> _clearTokens() async {
    _token = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
  }

  // Get headers with authorization
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // POST /api/Auth/register
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode(request.toJson()),
      );

      print('Register Response Status: ${response.statusCode}');
      print('Register Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(jsonData);
        await _saveTokens(authResponse.token, authResponse.refreshToken);
        await _saveUser(authResponse.user);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Đăng ký thất bại: ${response.body}',
        );
      }
    } catch (e) {
      print('Register Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // POST /api/Auth/login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode(request.toJson()),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(jsonData);
        await _saveTokens(authResponse.token, authResponse.refreshToken);
        await _saveUser(authResponse.user);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['message'] ?? 'Đăng nhập thất bại: ${response.body}',
        );
      }
    } catch (e) {
      print('Login Error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // POST /api/Auth/refresh
  Future<AuthResponse> refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('Không có refresh token');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _saveTokens(authResponse.token, authResponse.refreshToken);
        await _saveUser(authResponse.user);
        return authResponse;
      } else {
        await _clearTokens();
        throw Exception('Phiên đăng nhập hết hạn');
      }
    } catch (e) {
      await _clearTokens();
      throw Exception('Lỗi làm mới token: $e');
    }
  }

  // POST /api/Auth/revoke
  Future<void> revokeToken() async {
    if (_refreshToken == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/revoke'),
        headers: _getHeaders(),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
    } catch (e) {
      // Ignore errors on revoke
    }
  }

  // POST /api/Auth/logout
  Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('$baseUrl/logout'), headers: _getHeaders())
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Ignore errors on logout - always clear tokens
      print('Logout error (ignored): $e');
    } finally {
      // Always clear tokens even if API fails
      await _clearTokens();
    }
  }

  // GET /api/Auth/profile
  Future<UserDto> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final user = UserDto.fromJson(jsonDecode(response.body));
        await _saveUser(user);
        return user;
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshAccessToken();
        return getProfile();
      } else {
        throw Exception('Không thể lấy thông tin profile');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // PUT /api/Auth/profile
  Future<UserDto> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final user = UserDto.fromJson(jsonDecode(response.body));
        await _saveUser(user);
        return user;
      } else if (response.statusCode == 401) {
        await refreshAccessToken();
        return updateProfile(request);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // POST /api/Auth/change-password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await refreshAccessToken();
        return changePassword(request);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Đổi mật khẩu thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // GET /api/Auth/validate
  Future<bool> validateToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // GET /api/Auth/me
  Future<UserDto> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final user = UserDto.fromJson(jsonDecode(response.body));
        await _saveUser(user);
        return user;
      } else if (response.statusCode == 401) {
        await refreshAccessToken();
        return getCurrentUser();
      } else {
        throw Exception('Không thể lấy thông tin người dùng');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // POST /api/Auth/revoke-all
  Future<void> revokeAllTokens() async {
    try {
      await http.post(Uri.parse('$baseUrl/revoke-all'), headers: _getHeaders());
      await _clearTokens();
    } catch (e) {
      throw Exception('Lỗi khi thu hồi tokens: $e');
    }
  }
}
