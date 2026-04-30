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

  Future<Map<String, String>> getHeaders() async {
    _tokenCache ??= await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (_tokenCache != null) 'Authorization': 'Bearer $_tokenCache',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final String url = '${ApiConstants.baseUrl}$endpoint';
    debugPrint('[API] GET $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response =
          await http.get(Uri.parse(url), headers: headers);
      debugPrint('[API] GET $url → ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[API] GET $url ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    final String url = '${ApiConstants.baseUrl}$endpoint';
    debugPrint('[API] POST $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));
      debugPrint('[API] POST $url → ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[API] POST $url ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final String url = '${ApiConstants.baseUrl}$endpoint';
    debugPrint('[API] PUT $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response = await http.put(Uri.parse(url),
          headers: headers, body: jsonEncode(body));
      debugPrint('[API] PUT $url → ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[API] PUT $url ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final String url = '${ApiConstants.baseUrl}$endpoint';
    debugPrint('[API] DELETE $url');
    try {
      final Map<String, String> headers = await getHeaders();
      final http.Response response =
          await http.delete(Uri.parse(url), headers: headers);
      debugPrint('[API] DELETE $url → ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[API] DELETE $url ERROR: $e');
      rethrow;
    }
  }
}
