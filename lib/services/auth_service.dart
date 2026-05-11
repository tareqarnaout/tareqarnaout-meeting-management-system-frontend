import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cached so the GoRouter redirect doesn't hit storage on every navigation.
  static bool? _authStateCache;
  static int? _roleIdCache;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String token = data['token'] as String;
        final dynamic roleIdValue = data['roleId'] ?? data['roleID'];
        final int roleId = roleIdValue is int
            ? roleIdValue
            : int.parse(roleIdValue.toString());

        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'role_id', value: roleId.toString());

        ApiService.setTokenCache(token);
        _authStateCache = true;
        _roleIdCache = roleId;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> registerPassword({
    required String email,
    required String password,
    required String repeatedPass,
  }) async {
    try {
      final response = await _api.post('/auth/registerPass', {
        'email': email,
        'password': password,
        'repeatedPass': repeatedPass,
      });

      if (response.statusCode == 200) {
        return null;
      }

      final String body = response.body;
      if (body.isNotEmpty) {
        try {
          final dynamic decoded = jsonDecode(body);
          if (decoded is String) return decoded;
          if (decoded is Map && decoded.containsKey('message')) {
            return decoded['message'] as String;
          }
        } catch (_) {
          return body;
        }
      }

      if (response.statusCode == 400) {
        return 'Invalid request. Please check your details.';
      }
      return 'Registration failed. Please try again.';
    } catch (e) {
      debugPrint('[AuthService] registerPassword error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _authStateCache = false;
    _roleIdCache = null;
    ApiService.clearTokenCache();
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // Best-effort logout
    }
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'role_id');
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<int?> getRoleId() async {
    if (_roleIdCache != null) return _roleIdCache;
    final String? roleStr = await _storage.read(key: 'role_id');
    _roleIdCache = roleStr != null ? int.tryParse(roleStr) : null;
    return _roleIdCache;
  }

  Future<int?> getUserId() async {
    final String? token = await getToken();
    if (token == null) return null;
    try {
      final Map<String, dynamic> decoded = JwtDecoder.decode(token);
      final dynamic userId = decoded['nameid'] ??
          decoded['sub'] ??
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          decoded['UserId'] ??
          decoded['userId'];
      if (userId != null) {
        return int.tryParse(userId.toString());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserName() async {
    final String? token = await getToken();
    if (token == null) return null;
    try {
      final Map<String, dynamic> decoded = JwtDecoder.decode(token);
      final dynamic name = decoded['unique_name'] ??
          decoded['name'] ??
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
          decoded['UserName'] ??
          decoded['userName'] ??
          decoded['email'];
      return name?.toString();
    } catch (_) {
      return null;
    }
  }

  static void clearCaches() {
    _authStateCache = false;
    _roleIdCache = null;
    ApiService.clearTokenCache();
  }

  Future<bool> isAuthenticated() async {
    // Fast path: if we already know the user is logged in, just verify
    // the token hasn't expired since the last check.
    if (_authStateCache == true) {
      final String? token = await getToken();
      if (token == null || JwtDecoder.isExpired(token)) {
        await _clearStoredAuth();
        return false;
      }
      return true;
    }

    final String? token = await getToken();
    if (token == null || token.isEmpty) {
      _authStateCache = false;
      _roleIdCache = null;
      return false;
    }

    if (JwtDecoder.isExpired(token)) {
      await _clearStoredAuth();
      return false;
    }

    ApiService.setTokenCache(token);
    _authStateCache = true;
    return true;
  }

  Future<void> _clearStoredAuth() async {
    _authStateCache = false;
    _roleIdCache = null;
    ApiService.clearTokenCache();
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'role_id');
  }
}
