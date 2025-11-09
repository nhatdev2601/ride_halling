class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String role;

  RegisterRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

class AuthResponse {
  final String token;
  final String refreshToken;
  final DateTime expires;
  final UserDto user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.expires,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expires: json['expires'] != null
          ? DateTime.parse(json['expires'] as String)
          : DateTime.now(),
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : UserDto.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'expires': expires.toIso8601String(),
    'user': user.toJson(),
  };
}

class UserDto {
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final DateTime createdAt;

  UserDto({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory UserDto.empty() {
    return UserDto(
      userId: '',
      fullName: '',
      phone: '',
      email: '',
      role: '',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
  };
}

class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'currentPassword': currentPassword, 'newPassword': newPassword};
  }
}

class UpdateProfileRequest {
  final String? fullName;
  final String? phone;

  UpdateProfileRequest({this.fullName, this.phone});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['fullName'] = fullName;
    if (phone != null) data['phone'] = phone;
    return data;
  }
}
