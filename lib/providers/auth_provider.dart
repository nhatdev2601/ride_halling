import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserDto? _user;
  String? _error;

  AuthStatus get status => _status;
  UserDto? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.loadSavedAuth();
      if (_authService.isAuthenticated) {
        _user = _authService.currentUser;
        _status = AuthStatus.authenticated;

        // Validate token
        final isValid = await _authService.validateToken();
        if (!isValid) {
          // Try to refresh
          try {
            await _authService.refreshAccessToken();
            _user = _authService.currentUser;
            _status = AuthStatus.authenticated;
          } catch (e) {
            _status = AuthStatus.unauthenticated;
            _user = null;
          }
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);

      _user = response.user;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
      _user = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        role: role,
      );
      final response = await _authService.register(request);

      _user = response.user;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
      _user = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignore logout errors
    }

    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    if (_user == null) return false;

    try {
      final request = UpdateProfileRequest(fullName: fullName, phone: phone);
      final updatedUser = await _authService.updateProfile(request);
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _authService.changePassword(request);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      final user = await _authService.getCurrentUser();
      _user = user;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
