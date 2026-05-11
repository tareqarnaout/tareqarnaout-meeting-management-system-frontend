import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<List<AppUser>> getUsers() async {
    final response = await _api.get('/meetings/users');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((dynamic item) =>
              AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    debugPrint('[UserService] getUsers failed: ${response.statusCode}');
    throw Exception('Failed to load users');
  }

  Future<bool> addUser({
    required String fullName,
    required String email,
    required int roleId,
  }) async {
    final response = await _api.post('/auth/addUser', {
      'fullName': fullName,
      'email': email,
      'RoleID': roleId,
    });
    return response.statusCode == 200;
  }
}
