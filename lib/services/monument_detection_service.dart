import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Detection {
  final List<int> bbox;
  final double confidence;
  final String landmark;
  final double score;

  Detection({
    required this.bbox,
    required this.confidence,
    required this.landmark,
    required this.score,
  });
}

class DetectionResponse {
  final String requestId;
  final int numDetections;
  final List<Detection> detections;

  DetectionResponse({
    required this.requestId,
    required this.numDetections,
    required this.detections,
  });

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    List<Detection> detections = [];

    for (var detection in json['detections']) {
      // Get the top match from matches array
      final topMatch = detection['matches'][0];

      detections.add(Detection(
        bbox: List<int>.from(detection['bbox']),
        confidence: detection['confidence'],
        landmark: topMatch['landmark'],
        score: topMatch['score'],
      ));
    }

    return DetectionResponse(
      requestId: json['request_id'],
      numDetections: json['num_detections'],
      detections: detections,
    );
  }
}

class MonumentDetectionService {
  static String get baseUrl =>
      dotenv.env['CV_BASE_URL'] ?? 'http://192.168.1.24:8000';

  static Future<DetectionResponse> detectMonument(Uint8List imageBytes) async {
    try {
      final url = Uri.parse('$baseUrl/recognize');
      print('Sending detection request to: $url');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add the image file
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg',
      ));

      // Send the request
      final response =
          await request.send().timeout(const Duration(seconds: 15));

      // Get response
      final responseData = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse response
        final Map<String, dynamic> jsonData = json.decode(responseData);
        print('Detection response received: $jsonData');

        return DetectionResponse.fromJson(jsonData);
      } else {
        print('Error response: $responseData');
        throw Exception('Failed to detect monument: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in detectMonument: $e');
      throw Exception('Error detecting monument: $e');
    }
  }
}
