// lib/viewmodels/location_viewmodel.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import '../repositories/compass_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/storage_repository.dart';

class LocationViewModel extends ChangeNotifier {
  final LocationRepository _locationRepository;
  final CompassRepository _compassRepository;
  final StorageRepository _storageRepository;

  // State variables
  bool _isTracking = false;
  bool _isInitialized = false;
  String? _errorMessage;
  LocationModel? _currentLocation;
  double? _lastHeading;

  // Stream subscriptions
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _intervalTimer;

  // Config
  bool _saveToStorage = true;

  // Getters
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  LocationModel? get currentLocation => _currentLocation;

  // Constructor
  LocationViewModel({
    required LocationRepository locationRepository,
    required CompassRepository compassRepository,
    required StorageRepository storageRepository,
  })  : _locationRepository = locationRepository,
        _compassRepository = compassRepository,
        _storageRepository = storageRepository {
    // Load cached location data on startup
    _loadLocationFromStorage();
  }

  // Load location data from storage
  Future<void> _loadLocationFromStorage() async {
    try {
      final storedLocation = await _storageRepository.getLocationData();
      if (storedLocation != null) {
        _currentLocation = storedLocation;
        _lastHeading = storedLocation.heading;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading location from storage: $e');
    }
  }

  // Initialize location services and permissions
  Future<bool> initialize() async {
    try {
      final hasPermission = await _locationRepository.checkLocationPermission();
      if (!hasPermission) {
        _setError('Location permissions not granted');
        return false;
      }

      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to initialize location services: $e');
      return false;
    }
  }

  // Start tracking location
  Future<bool> startTracking({
    int? intervalSeconds,
    int? distanceFilter,
    int? orientationFilter,
    bool trackHeading = true,
    bool saveToStorage = true,
  }) async {
    if (_isTracking) {
      stopTracking();
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    _isTracking = true;
    _saveToStorage = saveToStorage;
    _errorMessage = null;
    notifyListeners();

    // Setup interval-based updates
    if (intervalSeconds != null && intervalSeconds > 0) {
      _intervalTimer = Timer.periodic(
          Duration(seconds: intervalSeconds), (_) => _updateCurrentLocation());
    }

    // Setup distance-based updates
    if (distanceFilter != null) {
      _positionSubscription = _locationRepository
          .getPositionStream(distanceFilter: distanceFilter)
          .listen((position) => _handlePositionUpdate(position),
              onError: (e) => _setError('Location stream error: $e'));
    }

    // Setup heading tracking
    if (trackHeading && _compassRepository.isCompassAvailable()) {
      _compassSubscription = _compassRepository.getCompassStream()?.listen(
          (event) => _handleCompassUpdate(
                event,
                orientationFilter: orientationFilter,
              ),
          onError: (e) => print('Compass error: $e'));
    }

    // Get initial location
    _updateCurrentLocation();

    return true;
  }

  // Stop tracking
  void stopTracking() {
    _isTracking = false;
    _intervalTimer?.cancel();
    _intervalTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _compassSubscription?.cancel();
    _compassSubscription = null;
    notifyListeners();
  }

  // Get latest location data (from storage if available and not stale, otherwise from device)
  Future<LocationModel?> getLocation({Duration? maxAge}) async {
    // If we have maxAge parameter, check if stored location is recent enough
    if (maxAge != null) {
      final isStale = await _storageRepository.isLocationStale(maxAge);

      // If stored location is stale or doesn't exist, update from device
      if (isStale) {
        await _updateCurrentLocation();
      } else if (_currentLocation == null) {
        // If we don't have it in memory, load from storage
        await _loadLocationFromStorage();
      }
    }
    // If no maxAge specified but no current location, update it
    else if (_currentLocation == null) {
      await _updateCurrentLocation();
    }

    return _currentLocation;
  }

  // Handle position updates
  void _handlePositionUpdate(Position position) {
    _updateLocationData(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // Handle compass updates
  void _handleCompassUpdate(
    CompassEvent event, {
    int? orientationFilter,
  }) {
    if (event.heading == null) return;

    bool shouldUpdate = _lastHeading == null;

    if (!shouldUpdate && orientationFilter != null) {
      double diff = (_lastHeading! - event.heading!).abs();
      // Account for 0/360 degree boundary
      if (diff > 180) diff = 360 - diff;
      shouldUpdate = diff >= orientationFilter;
    }

    if (shouldUpdate) {
      _lastHeading = event.heading;

      // Update location with new heading if we have location
      if (_currentLocation != null) {
        _updateLocationData(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          heading: _lastHeading,
        );
      }
    }
  }

  // Update current location from device
  Future<void> _updateCurrentLocation() async {
    try {
      final position = await _locationRepository.getCurrentPosition();
      if (position != null) {
        _updateLocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          heading: _lastHeading,
        );
      }
    } catch (e) {
      _setError('Error getting current location: $e');
    }
  }

  // Update location data and notify listeners
  void _updateLocationData({
    required double latitude,
    required double longitude,
    double? heading,
  }) {
    _currentLocation = LocationModel(
      latitude: latitude,
      longitude: longitude,
      heading: heading ?? _lastHeading,
      timestamp: DateTime.now(),
    );

    notifyListeners();

    // Save to persistent storage if enabled
    if (_saveToStorage) {
      _storageRepository.saveLocationData(_currentLocation!).catchError((e) {
        print('Storage error: $e');
        return false; // Return a value to satisfy the Future<bool> requirement
      });
    }
  }

  // Set error message and notify listeners
  void _setError(String message) {
    _errorMessage = message;
    print('LocationViewModel: $message');
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
