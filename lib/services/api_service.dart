import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // In-memory token cache — avoids a secure storage read on every request.
  static String? _tokenCache;

  static void setTokenCache(String token) => _tokenCache = token;
  static void clearTokenCache() => _tokenCache = null;

  /// Called when any API response returns 401, signalling an expired session.
  static VoidCallback? onSessionExpired;

  static bool _handlingExpiry = false;

  void _handleResponseIfUnauthorized(http.Response response) {
    if (response.statusCode == 401 && !_handlingExpiry) {
      _handlingExpiry = true;
      _tokenCache = null;
      _storage.delete(key: 'auth_token');
      _storage.delete(key: 'role_id');
      onSessionExpired?.call();
      // Reset after a short delay so future 401s are still caught.
      Future<void>.delayed(const Duration(seconds: 1), () {
        _handlingExpiry = false;
      });
    }
  }

  Future<Map<String, String>> getHeaders() async {
    _tokenCache ??= await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (_tokenCache != null) 'Authorization': 'Bearer $_tokenCache',
    };
  }

  String _normalizeBaseUrl(String baseUrl) {
    final String trimmed = baseUrl.trim();
    final Uri uri = Uri.parse(trimmed);
    if (uri.path.isEmpty && trimmed.endsWith('api')) {
      final int index = trimmed.lastIndexOf('api');
      return '${trimmed.substring(0, index)}/api';
    }
    return trimmed;
  }

  String _buildUrl(String endpoint) {
    final String normalizedBase = _normalizeBaseUrl(ApiConstants.baseUrl);
    final String base = normalizedBase.endsWith('/')
        ? normalizedBase.substring(0, normalizedBase.length - 1)
        : normalizedBase;
    final String path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  Future<http.Response> get(String endpoint) async {
    final String url = _buildUrl(endpoint);
    debugPrint('[API] GET $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response =
          await http.get(Uri.parse(url), headers: headers);
      debugPrint('[API] GET $url → ${response.statusCode}');
      _handleResponseIfUnauthorized(response);
      return response;
    } catch (e) {
      debugPrint('[API] GET $url ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    final String url = _buildUrl(endpoint);
    debugPrint('[API] POST $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));
      debugPrint('[API] POST $url → ${response.statusCode}');
      _handleResponseIfUnauthorized(response);
      return response;
    } catch (e) {
      debugPrint('[API] POST $url ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final String url = _buildUrl(endpoint);
    debugPrint('[API] PUT $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response = await http.put(Uri.parse(url),
          headers: headers, body: jsonEncode(body));
      debugPrint('[API] PUT $url → ${response.statusCode}');
      _handleResponseIfUnauthorized(response);
      return response;
    } catch (e) {
      debugPrint('[API] PUT $url ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final String url = _buildUrl(endpoint);
    debugPrint('[API] DELETE $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response =
          await http.delete(Uri.parse(url), headers: headers);
      debugPrint('[API] DELETE $url → ${response.statusCode}');
      _handleResponseIfUnauthorized(response);
      return response;
    } catch (e) {
      debugPrint('[API] DELETE $url ERROR: $e');
      rethrow;
    }
  }
}
