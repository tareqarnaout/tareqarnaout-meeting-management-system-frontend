import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {

        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(key: 'auth_token', value: data['token'] as String);
        await _storage.write(
            key: 'role_id', value: (data['roleID'] as int).toString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
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
    final String? roleStr = await _storage.read(key: 'role_id');
    return roleStr != null ? int.tryParse(roleStr) : null;
  }

  Future<bool> isAuthenticated() async {
    final String? token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
