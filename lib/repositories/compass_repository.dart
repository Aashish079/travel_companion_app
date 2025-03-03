import 'package:flutter_compass/flutter_compass.dart';

class CompassRepository {
  // Check if compass is available
  bool isCompassAvailable() {
    return FlutterCompass.events != null;
  }

  // Get compass stream
  Stream<CompassEvent>? getCompassStream() {
    return FlutterCompass.events;
  }
}
