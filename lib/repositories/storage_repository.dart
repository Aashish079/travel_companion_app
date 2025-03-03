import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

class StorageRepository {
  static const String _locationKey = 'last_location_data';

  // Save location data to persistent storage
  Future<bool> saveLocationData(LocationModel locationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(locationData.toJson());
      return await prefs.setString(_locationKey, jsonData);
    } catch (e) {
      print('Error saving location data: $e');
      return false;
    }
  }

  // Get location data from persistent storage
  Future<LocationModel?> getLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_locationKey);

      if (jsonData == null) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(jsonData);
      return LocationModel(
        latitude: data['latitude'],
        longitude: data['longitude'],
        heading: data['heading'],
        timestamp: DateTime.parse(data['timestamp']),
      );
    } catch (e) {
      print('Error retrieving location data: $e');
      return null;
    }
  }

  // Check if location data is older than specified duration
  Future<bool> isLocationStale(Duration maxAge) async {
    try {
      final locationData = await getLocationData();
      if (locationData == null) return true;

      final now = DateTime.now();
      final difference = now.difference(locationData.timestamp);
      return difference > maxAge;
    } catch (e) {
      print('Error checking location staleness: $e');
      return true;
    }
  }
}
