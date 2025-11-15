import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/auth_user.dart';
import '../services/api_client.dart';

class AuthRepository {
  AuthRepository({
    ApiClient? apiClient,
    GoogleSignIn? googleSignIn,
    String? webClientId,
    String? serverClientId,
  })  : _apiClient = apiClient ?? ApiClient(),
        _googleSignIn = googleSignIn ??
            (kIsWeb
                ? GoogleSignIn(
                    scopes: ['email', 'profile'],
                    clientId: webClientId ??
                        "851473230830-pluq3delcr6gdo5ifm0ik9tb343hafpf.apps.googleusercontent.com",
                    // Explicitly do NOT pass serverClientId on Web
                  )
                : GoogleSignIn(
                    scopes: ['email', 'profile'],
                    serverClientId: serverClientId ??
                        "851473230830-pluq3delcr6gdo5ifm0ik9tb343hafpf.apps.googleusercontent.com",
                    // Explicitly do NOT pass clientId on Android/iOS
                  ));

  final ApiClient _apiClient;
  final GoogleSignIn? _googleSignIn;
  bool _isGoogleSignInInProgress = false;

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/login',
      {'email': email, 'password': password},
    );
    return _sessionFromResponse(response);
  }

  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _post(
      '/auth/register',
      {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );
    return _sessionFromResponse(response);
  }

  Future<AuthSession> signInWithGoogle() async {
    final google = _googleSignIn;
    if (google == null) {
      throw const AuthException('Google sign-in is not configured for this platform');
    }
    
    // Prevent concurrent sign-in attempts
    if (_isGoogleSignInInProgress) {
      throw const AuthException('Google sign-in is already in progress');
    }
    
    try {
      _isGoogleSignInInProgress = true;
      
      // Google Sign-In library handles account switching automatically
      // No need to sign out first - this was causing "request id mismatch" errors
      final account = await google.signIn();
      if (account == null) {
        throw const AuthException('Sign-in aborted by user');
      }
      
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      
      if (idToken == null) {
        // Provide more detailed error message
        String errorDetails = 'Failed to retrieve Google identity token. ';
        if (accessToken == null) {
          errorDetails += 'Both ID token and access token are null. ';
        } else {
          errorDetails += 'Access token was retrieved but ID token is missing. ';
        }
        errorDetails += 'Please verify:\n'
            '1. serverClientId is set to your Web Client ID (not Android Client ID)\n'
            '2. Android OAuth client is created in Google Cloud Console\n'
            '3. SHA-1 fingerprint matches in Google Cloud Console\n'
            '4. OAuth consent screen is configured\n'
            '5. Your account is added as a test user';
        throw AuthException(errorDetails);
      }
      
      final response = await _post(
        '/auth/oauth/google',
        {'idToken': idToken},
      );
      return _sessionFromResponse(response);
    } on PlatformException catch (error) {
      String message = error.message ?? 'Google sign-in is not available on this device';
      if (error.code == 'sign_in_failed') {
        message += '\n\nPossible causes:\n'
            '- OAuth client not configured correctly\n'
            '- SHA-1 fingerprint mismatch\n'
            '- Missing serverClientId configuration';
      }
      throw AuthException(message);
    } catch (error) {
      if (error is AuthException) rethrow;
      // Safely convert error to string to avoid JavaScript interop issues on web
      final errorMessage = _safeErrorToString(error);
      throw AuthException('Google sign-in error: $errorMessage');
    } finally {
      _isGoogleSignInInProgress = false;
    }
  }

  Future<AuthSession> signInWithApple() async {
    if (!defaultTargetPlatformSupportsAppleSignIn) {
      throw const AuthException('Apple Sign In is only available on iOS/macOS');
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw const AuthException('Failed to obtain Apple identity token');
      }
      final response = await _post(
        '/auth/oauth/apple',
        {
          'identityToken': identityToken,
          if (credential.givenName != null || credential.familyName != null)
            'fullName': {
              if (credential.givenName != null) 'firstName': credential.givenName,
              if (credential.familyName != null) 'lastName': credential.familyName,
            },
        },
      );
      return _sessionFromResponse(response);
    } on PlatformException catch (error) {
      throw AuthException(error.message ?? 'Apple Sign In failed');
    } catch (error) {
      if (error is AuthException) rethrow;
      throw AuthException(_safeErrorToString(error));
    }
  }

  Future<AuthSession> refreshSession(String refreshToken) async {
    final response = await _post(
      '/auth/refresh',
      {'refreshToken': refreshToken},
    );
    return _sessionFromResponse(response);
  }

  Future<AuthSession> signInAsAdmin({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/admin/login',
      {
        'email': email,
        'password': password,
      },
    );
    return _sessionFromResponse(response);
  }

  Future<Map<String, dynamic>> requestPasswordReset({required String email}) async {
    // Returns response which may contain otp for development
    // When SMTP is configured, backend won't need to return the otp
    return await _post(
      '/auth/forgot-password',
      {'email': email},
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _post(
      '/auth/verify-otp',
      {
        'email': email,
        'otp': otp,
      },
    );
  }

  Future<AuthSession> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _post(
      '/auth/reset-password',
      {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
    // Reset password now returns auth session (auto-login)
    return _sessionFromResponse(response);
  }

  Future<AuthSession> updateProfile({
    required String accessToken,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final response = await _put(
      '/auth/profile',
      {
        if (displayName != null) 'displayName': displayName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return _sessionFromResponse(response);
  }

  AuthSession _sessionFromResponse(Map<String, dynamic> json) {
    if (!json.containsKey('user')) {
      throw const AuthException('Unexpected server response');
    }
    final userJson = json['user'] as Map<String, dynamic>;
    final user = AuthUser(
      id: userJson['id'] as String,
      email: userJson['email'] as String,
      displayName: userJson['displayName'] as String,
      avatarUrl: userJson['avatarUrl'] as String?,
      phoneNumber: userJson['phoneNumber'] as String?,
    );
    final accessToken = json['accessToken'] as String;
    final refreshToken = json['refreshToken'] as String?;
    final expiresIn = json['expiresIn'] as int? ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: (refreshToken != null && refreshToken.isEmpty) ? null : refreshToken,
      expiresAt: expiresAt,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  /// Safely converts an error to a string, avoiding JavaScript interop issues on web
  String _safeErrorToString(dynamic error) {
    try {
      if (error == null) return 'Unknown error';
      if (error is String) return error;
      if (error is Error) return error.toString();
      // For other types, try toString() but catch any interop issues
      return error.toString();
    } catch (_) {
      return 'An error occurred during Google sign-in';
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload) async {
    try {
      return await _apiClient.post(path, body: jsonEncode(payload));
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } catch (error) {
      throw AuthException(_safeErrorToString(error));
    }
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) async {
    try {
      return await _apiClient.put(path, body: jsonEncode(payload), headers: headers);
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } catch (error) {
      throw AuthException(_safeErrorToString(error));
    }
  }
}

bool get defaultTargetPlatformSupportsAppleSignIn {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException($message)';
}

