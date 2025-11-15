import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  static const _sessionStorageKey = 'auth_session';

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  AuthSession? _session;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  AuthSession? get session => _session;
  String? get accessToken => _session?.accessToken;
  String? get refreshToken => _session?.refreshToken;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _session?.isAdmin ?? false;

  void clearError() {
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
    _errorMessage = null;
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_sessionStorageKey);
    if (stored == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    try {
      final session = AuthSession.fromJson(json.decode(stored) as Map<String, dynamic>);
      _session = session;
      _user = session.user;
      if (session.isExpired && session.refreshToken != null) {
        await refreshSession(silent: true);
      } else if (session.isExpired) {
        await signOut();
      } else {
        _setStatus(AuthStatus.authenticated);
      }
    } catch (_) {
      await prefs.remove(_sessionStorageKey);
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _execute(() => _authRepository.signInWithEmail(email: email, password: password));
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _execute(
      () => _authRepository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    await _execute(_authRepository.signInWithGoogle);
  }

  Future<void> signInWithApple() async {
    await _execute(_authRepository.signInWithApple);
  }

  Future<void> signInAsAdmin(String email, String password) async {
    await _execute(() => _authRepository.signInAsAdmin(email: email, password: password));
  }

  String? _resetOtp;
  String? get resetOtp => _resetOtp;
  String? _resetEmail;
  String? get resetEmail => _resetEmail;

  Future<void> requestPasswordReset(String email) async {
    _errorMessage = null;
    _resetOtp = null;
    _resetEmail = email;
    _setStatus(AuthStatus.authenticating);
    try {
      final response = await _authRepository.requestPasswordReset(email: email);
      // In development, backend may return otp if SMTP is not configured
      _resetOtp = response['otp'] as String?;
      _errorMessage = null;
      _setStatus(AuthStatus.unauthenticated);
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _setStatus(AuthStatus.error);
    } catch (error) {
      _errorMessage = error.toString();
      _setStatus(AuthStatus.error);
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _errorMessage = null;
    _setStatus(AuthStatus.authenticating);
    try {
      await _authRepository.verifyOtp(email: email, otp: otp);
      _errorMessage = null;
      _setStatus(AuthStatus.unauthenticated);
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _setStatus(AuthStatus.error);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _errorMessage = null;
    _setStatus(AuthStatus.authenticating);
    try {
      // Reset password now returns auth session (auto-login)
      final session = await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      await _applySession(session);
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _setStatus(AuthStatus.error);
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStorageKey);
    _user = null;
    _session = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final token = accessToken;
    if (token == null) {
      _errorMessage = 'Not authenticated';
      _setStatus(AuthStatus.error);
      return;
    }

    _errorMessage = null;
    _setStatus(AuthStatus.authenticating);

    try {
      final session = await _authRepository.updateProfile(
        accessToken: token,
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
      );
      await _applySession(session);
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _setStatus(AuthStatus.error);
    } catch (error) {
      _errorMessage = error.toString();
      _setStatus(AuthStatus.error);
    }
  }

  Future<void> _execute(Future<AuthSession> Function() operation) async {
    _errorMessage = null;
    _setStatus(AuthStatus.authenticating);

    try {
      final session = await operation();
      await _applySession(session);
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _setStatus(AuthStatus.error);
    } catch (error) {
      _errorMessage = error.toString();
      _setStatus(AuthStatus.error);
    }
  }

  Future<void> refreshSession({bool silent = false}) async {
    final token = _session?.refreshToken;
    if (token == null || token.isEmpty) {
      if (_session?.isAdmin ?? false) {
        _setStatus(AuthStatus.authenticated);
        return;
      }
      await signOut();
      return;
    }

    if (!silent) {
      _setStatus(AuthStatus.authenticating);
    }

    try {
      final session = await _authRepository.refreshSession(token);
      await _applySession(session, notify: !silent);
      if (silent) {
        _setStatus(AuthStatus.authenticated);
      }
    } on AuthException catch (error) {
      _errorMessage = error.message;
      await signOut();
    } catch (error) {
      _errorMessage = error.toString();
      await signOut();
    }
  }

  Future<void> _applySession(AuthSession session, {bool notify = true}) async {
    _session = session;
    _user = session.user;
    _errorMessage = null;
    await _persistSession(session);
    if (notify) {
      _setStatus(AuthStatus.authenticated);
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStorageKey, json.encode(session.toJson()));
  }

  void _setStatus(AuthStatus status, {bool silent = false}) {
    _status = status;
    if (!silent) notifyListeners();
  }
}

