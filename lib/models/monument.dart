import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Monument {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;
  final double popularity;
  final bool indoor;
  final String description;
  final String imageUrl;
  final String location;

  Monument(
      {required this.id,
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.type,
      required this.popularity,
      required this.indoor,
      required this.description,
      required this.imageUrl,
      required this.location});

  factory Monument.fromJson(Map<String, dynamic> json) {
    return Monument(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        latitude: (json['latitude'] ?? 0.0).toDouble(),
        longitude: (json['longitude'] ?? 0.0).toDouble(),
        type: json['type'] ?? '',
        popularity: (json['popularity'] ?? 0.0).toDouble(),
        indoor: json['indoor'] ?? false,
        description: json['description'] ?? '',
        imageUrl: json['image_url'] ?? '/assets/placeholder.jpg',
        location: json['location'] ?? '');
  }

  // Helper method to get popularity as percentage string
  String get popularityPercentage => '${(popularity * 100).toInt()}%';

  // Helper method to get color based on monument type
  Color get typeColor {
    switch (type) {
      case 'Hindu Temple':
        return Colors.orange;
      case 'Buddhist Temple':
      case 'Buddhist Stupa':
        return Colors.amber;
      case 'Historical Monument':
      case 'Historical Site':
        return Colors.blue;
      case 'Museum':
        return Colors.purple;
      case 'Garden':
      case 'Park':
        return Colors.green;
      case 'Palace':
        return Colors.red;
      case 'Cave':
        return Colors.brown;
      default:
        return Colors.teal;
    }
  }

  // Get the full image URL including the base URL
  String get fullImageUrl {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.24:8000';
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else {
      return '$baseUrl$imageUrl';
    }
  }
}
