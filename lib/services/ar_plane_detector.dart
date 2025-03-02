import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
// import 'package:ar_flutter_plugin/datatypes/ar_plane.dart'; // Import for plane data
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

// Enum to represent plane alignment since the imported one isn't available
enum CustomPlaneAlignment {
  horizontal,
  vertical
}

class ARPlaneDetector {
  List<ARPlaneAnchor> detectedPlanes = [];
  
  void onPlaneDetected(ARPlaneAnchor anchor) {
    detectedPlanes.add(anchor);
  }
  
  // Find the best plane to place chat text (preferably vertical surfaces)
  ARPlaneAnchor? findBestPlaneForText() {
    if (detectedPlanes.isEmpty) return null;
    
    // Sort planes by estimated size (if possible)
    final sortedPlanes = List<ARPlaneAnchor>.from(detectedPlanes);
    
    // Since we can't directly access plane properties, we'll use the first available plane
    // In a real implementation, you would determine which planes are vertical
    // based on their transform matrix or other available properties
    
    return sortedPlanes.first;
  }
  
  // Calculate optimal position for text on a plane
  Vector3 calculateOptimalTextPosition(ARPlaneAnchor plane) {
    // Since we can't access center and normal directly, we'll create a 
    // position based on the plane's transform matrix
    
    // Get the position vector from the transform matrix (4th column)
    final transform = plane.transformation;
    final position = Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z
    );
    
    // Add a small offset in the Y direction as a simple alternative
    // to using the normal vector which isn't directly accessible
    position.y += 0.05; // 5cm offset upward
    
    return position;
  }
  
  // Helper method to approximate if a plane is vertical based on its transform
  bool isPlaneVertical(ARPlaneAnchor plane) {
    // Get the y-axis component from the transform matrix (2nd column)
    final yAxisY = plane.transformation.getColumn(1).y.abs();
    
    // If the y-component of the y-axis is close to 0, the plane is likely vertical
    return yAxisY < 0.3; // Threshold can be adjusted
  }
}