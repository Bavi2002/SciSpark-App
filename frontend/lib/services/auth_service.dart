import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/constants/api_constants.dart';

class AuthService {
  static Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role'] ?? 'teacher'); // Adjust based on response
      await prefs.setString('userId', data['userId']?.toString() ?? ''); // Store userId if provided
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUserId = prefs.getString('userId');
    if (cachedUserId != null && cachedUserId.isNotEmpty) {
      return cachedUserId; // Return cached userId if available
    }

    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['id']?.toString();
        if (userId != null) {
          await prefs.setString('userId', userId); // Cache userId
          return userId;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user ID: $e');
      return null;
    }
  }

  static Future<void> saveTokenAndRole(String token, String role, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setString('userId', userId ?? '');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
  }
}