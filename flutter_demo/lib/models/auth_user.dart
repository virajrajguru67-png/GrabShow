class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.phoneNumber,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? phoneNumber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.isAdmin = false,
  });

  final AuthUser user;
  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  final bool isAdmin;

  bool get isExpired => DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 30)));

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'expiresAt': expiresAt.toIso8601String(),
      if (refreshToken != null) 'refreshToken': refreshToken,
      'user': user.toJson(),
      'isAdmin': isAdmin,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }
}

