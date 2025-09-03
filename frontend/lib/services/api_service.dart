import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/api_constants.dart';
import 'package:frontend/models/experiment.dart';
import 'package:frontend/services/auth_service.dart';

class ApiService {

  static Future<Map<String, dynamic>> askQuestion(
    String experimentId,
    String question,
  ) async {
    final response = await request(
      '/api/ai/ask',
      'POST',
      body: {'experimentId': experimentId, 'question': question},
      authRequired: true,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to get AI response: ${response.statusCode}');
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
      } else {
        throw Exception('No token found. Please login again.');
      }
    }

    http.Response response;
    switch (method.toUpperCase()) {
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

    print('Request to $url ($method): Status ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 401) {
      await AuthService.logout();
      throw Exception('Session expired. Please login again.');
    }

    if (response.statusCode >= 400) {
      if (response.body.startsWith('<!')) {
        throw Exception('Received HTML response instead of JSON. Check backend URL or endpoint: $endpoint');
      }
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Request failed with status ${response.statusCode}');
      } catch (e) {
        throw Exception('Invalid response format: ${response.body}');
      }
    }

    return response;
  }

  static Future<List<Experiment>> getExperiments() async {
    final response = await request('/api/experiments', 'GET', authRequired: false);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Experiment.fromJson(json)).toList();
  }

  static Future<List<Experiment>> getTeacherExperiments(String teacherId) async {
    final response = await request('/api/experiments/teacher/$teacherId', 'GET', authRequired: true);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Experiment.fromJson(json)).toList();
  }

  static Future<Map<String, dynamic>> addExperiment(Map<String, dynamic> experimentData) async {
    final response = await request('/api/experiments/add', 'POST', body: experimentData);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getExperimentById(String id) async {
    final response = await request('/api/experiments/$id', 'GET');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateExperiment(String id, Map<String, dynamic> experimentData) async {
    final response = await request('/api/experiments/$id', 'PUT', body: experimentData);
    return jsonDecode(response.body);
  }

  static Future<void> deleteExperiment(String id) async {
    await request('/api/experiments/$id', 'DELETE');
  }

  static Future<Map<String, dynamic>> addStep(String experimentId, Map<String, dynamic> stepData) async {
    final response = await request('/api/experiments/$experimentId/steps', 'POST', body: stepData);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateStep(String experimentId, int stepIndex, Map<String, dynamic> stepData) async {
    final response = await request('/api/experiments/$experimentId/steps/$stepIndex', 'PUT', body: stepData);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteStep(String experimentId, int stepIndex) async {
    final response = await request('/api/experiments/$experimentId/steps/$stepIndex', 'DELETE');
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> startExperiment(String experimentId) async {
    final response = await request('/api/student/progress/start', 'POST', body: {'experimentId': experimentId});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markStepCompleted(String experimentId, int stepNumber) async {
    final response = await request('/api/student/progress/step', 'POST', body: {
      'experimentId': experimentId,
      'stepNumber': stepNumber,
    });
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getStudentProgress() async {
    final response = await request('/api/student/progress', 'GET');
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getStudentAchievements() async {
    final response = await request('/api/student/achievements', 'GET');
    return jsonDecode(response.body);
  }
}