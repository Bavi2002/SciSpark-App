import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class OpenAIService {
  static const String _apiKey = OPENAI_API_KEY;
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, dynamic>> generateExperimentMetadata(String title) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Generate metadata for a science experiment titled "$title". Provide a description (50-100 words), subject area (e.g., Chemistry, Physics), difficulty level (Beginner, Intermediate, Advanced), and a list of 3-5 materials. Return the response in JSON format.'
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      }
      throw Exception('Failed to generate metadata: ${response.body}');
    } catch (e) {
      throw Exception('Error with OpenAI API: $e');
    }
  }

  static Future<List<Map<String, String>>> generateStepSuggestions(String experimentTitle) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content':
                  'Generate 3-5 step suggestions for a science experiment titled "$experimentTitle". Each step should have a text description and optional imageUrl or videoUrl (use placeholder URLs if needed). Return the response in JSON format as an array of objects with fields: text, imageUrl, videoUrl.'
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, String>>.from(jsonDecode(data['choices'][0]['message']['content']));
      }
      throw Exception('Failed to generate step suggestions: ${response.body}');
    } catch (e) {
      throw Exception('Error with OpenAI API: $e');
    }
  }
}