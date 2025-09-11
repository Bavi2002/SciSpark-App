import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Fetch parent data (progress, experiments, etc.)
  Future<List<dynamic>> fetchParentDashboardData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/parent/dashboard'),
      headers: {
        'Authorization': 'Bearer $token', // Pass the JWT token here
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Assuming your API returns a JSON list
    } else {
      throw Exception('Failed to load data');
    }
  }
}
