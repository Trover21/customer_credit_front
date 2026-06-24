import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  // Save token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Save role
  Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  // Get role
  Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  // Delete all data (Logout)
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Sign up
  Future<Map<String, dynamic>> signUp(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('${_apiService.baseUrl}/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await saveToken(data['token']);
      await saveRole(data['role']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to sign up');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${_apiService.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveToken(data['token']);
      await saveRole(data['role']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to login');
    }
  }

  // Forgot Password
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${_apiService.baseUrl}/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to send reset code');
    }
  }

  // Reset Password
  Future<void> resetPassword(String email, String resetCode, String newPassword) async {
    final response = await http.post(
      Uri.parse('${_apiService.baseUrl}/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'resetCode': resetCode,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to reset password');
    }
  }
  // --- NEW ADMIN FUNCTIONS ---

  Future<List<dynamic>> fetchUsers() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${_apiService.baseUrl}/api/auth/users'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final msg = jsonDecode(response.body)['message'] ?? 'Failed to fetch users';
      throw Exception(msg);
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('${_apiService.baseUrl}/api/auth/users/$userId/role'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': newRole}),
    );

    if (response.statusCode != 200) {
      final msg = jsonDecode(response.body)['message'] ?? 'Failed to update user';
      throw Exception(msg);
    }
  }

  Future<void> deleteUser(String userId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('${_apiService.baseUrl}/api/auth/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final msg = jsonDecode(response.body)['message'] ?? 'Failed to delete user';
      throw Exception(msg);
    }
  }
}
