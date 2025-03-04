import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' as ml_kit;

class DetectedObject {
  final String label;
  final int confidence;
  final Rect boundingBox;
  final Color color;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.color,
  });

  factory DetectedObject.fromMlKitObject(ml_kit.DetectedObject mlKitObject, int trackingId) {
    // Generate a consistent color based on the tracking ID
    final color = Colors.primaries[trackingId % Colors.primaries.length];
    
    String label = 'Unknown';
    int confidence = 0;
    
    if (mlKitObject.labels.isNotEmpty) {
      label = mlKitObject.labels.first.text;
      confidence = (mlKitObject.labels.first.confidence * 100).toInt();
    }
    
    return DetectedObject(
      label: label,
      confidence: confidence,
      boundingBox: mlKitObject.boundingBox,
      color: color,
    );
  }

  // For debugging and display purposes
  @override
  String toString() => '$label (${confidence}%)';
}