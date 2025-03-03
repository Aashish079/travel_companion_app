import '../models/location_model.dart';
import '../viewmodels/location_viewmodel.dart';

// Move typedefs to top level (outside the class)
typedef LocationUpdateCallback = void Function(LocationModel locationData);
typedef ErrorCallback = void Function(String message);

// This service provides a simple wrapper around the ViewModel
// for components that don't need the full reactivity
class LocationService {
  final LocationViewModel _locationViewModel;

  // Callbacks
  LocationUpdateCallback? onLocationUpdate;
  ErrorCallback? onError;

  LocationService(this._locationViewModel) {
    // Listen to location updates
    _locationViewModel.addListener(_handleViewModelUpdate);
  }

  void _handleViewModelUpdate() {
    // Forward location updates to callback
    if (_locationViewModel.currentLocation != null &&
        onLocationUpdate != null) {
      onLocationUpdate!(_locationViewModel.currentLocation!);
    }

    // Forward errors to callback
    if (_locationViewModel.errorMessage != null && onError != null) {
      onError!(_locationViewModel.errorMessage!);
    }
  }

  // Initialize and start tracking
  Future<bool> startTracking({
    int? intervalSeconds,
    int? distanceFilter,
    int? orientationFilter,
    bool trackHeading = true,
  }) async {
    return _locationViewModel.startTracking(
      intervalSeconds: intervalSeconds,
      distanceFilter: distanceFilter,
      orientationFilter: orientationFilter,
      trackHeading: trackHeading,
      saveToStorage: true,
    );
  }

  // Stop tracking
  void stopTracking() {
    _locationViewModel.stopTracking();
  }

  // Get the latest location data (from storage or device)
  Future<LocationModel?> getLocation({
    // If provided, will update location if stored data is older than this
    Duration? maxAge,
  }) {
    return _locationViewModel.getLocation(maxAge: maxAge);
  }

  // Clean up
  void dispose() {
    _locationViewModel.removeListener(_handleViewModelUpdate);
  }
}
