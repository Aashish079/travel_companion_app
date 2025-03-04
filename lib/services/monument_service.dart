import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_companion_app/models/monument.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MonumentService {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.24:8000';

  // Get all monuments from the API
  static Future<List<Monument>> getAllMonuments() async {
    try {
      final url = Uri.parse('$baseUrl/getMonuments');
      print('Fetching all monuments from: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

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
        throw Exception('Failed to load monuments: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getAllMonuments: $e');
      throw Exception('Error fetching monuments: $e');
    }
  }
}
