import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../models/experiment.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, dynamic>> askQuestion(
    String experimentId,
    String question,
  ) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/api/ai/ask'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your_jwt_token', // Replace with actual JWT
      },
      body: jsonEncode({'experimentId': experimentId, 'question': question}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get AI response: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> addExperiment(
    Map<String, dynamic> experimentData,
  ) async {
    print(experimentData);
    final response = await http.post(
      Uri.parse('$BASE_URL/api/experiments/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your_jwt_token', // Replace with actual JWT
      },
      body: jsonEncode(experimentData),
    );

    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add experiment: ${response.statusCode}');
    }
  }

  static Future<List<Experiment>> getExperiments() async {
    final response = await http.get(
      Uri.parse('$BASE_URL/api/experiments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your_jwt_token', // Replace with actual JWT
      },
    );

    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      print('Decoded response: $decoded');
      if (decoded is List) {
        return decoded.map<Experiment>((e) => Experiment.fromJson(e)).toList();
      } else if (decoded is Map && decoded.containsKey('experiments')) {
        final experiments = decoded['experiments'];
        if (experiments is List) {
          return experiments
              .map<Experiment>((e) => Experiment.fromJson(e))
              .toList();
        }
      }
      // If response is not a list or doesn't contain 'experiments', return empty list
      return [];
    } else {
      throw Exception('Failed to fetch experiments: ${response.statusCode}');
    }
  }

  static Future<http.Response> request(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) async {
    final url = Uri.parse('$BASE_URL$endpoint');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (authRequired) {
      final token = await AuthService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        response = await http.get(url, headers: headers);
    }

    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Session expired. Please login again.');
    }

    return response;
  }
}
