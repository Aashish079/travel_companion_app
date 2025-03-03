import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_companion_app/models/monument.dart'; // Update with your actual path

class RecommendationService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Get recommendations from the API
  static Future<List<Monument>> getRecommendations({String? prompt}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getRecommendations'),
        headers: {'accept': 'application/json'},
        body: prompt != null ? json.encode({'prompt': prompt}) : null,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Convert to list of Monument objects
        final List<Monument> monuments = data.entries
            .map((entry) => Monument.fromJson(entry.key, entry.value))
            .toList();

        // Sort by score (highest first)
        // monuments.sort((a, b) => b.score.compareTo(a.score));

        return monuments;
      } else {
        throw Exception(
            'Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recommendations: $e');
    }
  }
}
