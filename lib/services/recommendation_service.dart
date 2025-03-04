import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_companion_app/models/monument.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecommendationService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  // Get recommendations from the API
  static Future<List<Monument>> getRecommendations({String? prompt}) async {
    try {
      final url = Uri.parse('$baseUrl/getRecommendations');
      print('Sending request to: $url');

      final response = await http
          .post(
            url,
            headers: {
              'accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: prompt != null ? json.encode({'prompt': prompt}) : '',
          )
          .timeout(const Duration(seconds: 15)); // Add timeout

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse response as an array of monuments
        final List<dynamic> responseData = json.decode(response.body);
        print('Received ${responseData.length} monuments from API');

        // Convert to list of Monument objects
        final List<Monument> monuments =
            responseData.map((item) => Monument.fromJson(item)).toList();

        return monuments;
      } else {
        print('Error response: ${response.body}');
        throw Exception(
            'Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getRecommendations: $e');
      throw Exception('Error fetching recommendations: $e');
    }
  }
}
