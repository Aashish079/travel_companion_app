import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class ARManager {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;
  
  // For tracking recognized objects/landmarks
  final Map<String, Matrix4> recognizedObjects = {};
  
  // Method to be called from onARViewCreated callback
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;
    
    initializeAR();
  }
  
  // Initialize AR session
  Future<void> initializeAR() async {
    if (arSessionManager == null) {
      throw Exception('ARSessionManager is not initialized');
    }
    
    await arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: "assets/images/triangle.png",
      showWorldOrigin: true,
    );
    
    await arObjectManager!.onInitialize();
    // arAnchorManager does not have an onInitialize method
    
    // Start AR session
    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
  }
  
  // Handle tap on a plane or point
  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    // Place AR content at tap location
    var singleHitTestResult = hitTestResults.firstWhere(
      (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );
    
    // Store the transformation matrix for this location
    final landmark = "current_landmark";
    recognizedObjects[landmark] = singleHitTestResult.worldTransform;
  }
  
  // Add chat button at a specific recognized location
  Future<Future<bool?>?> addChatButtonAt(String landmarkName) async {
    if (!recognizedObjects.containsKey(landmarkName)) return null;
    
    final node = ARNode(
      type: NodeType.webGLB,
      uri: "assets/models/chat_button.glb",
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(0, 0, 0),
      rotation: Vector4(1, 0, 0, 0),
    );
    
    return arObjectManager!.addNode(node, planeAnchor: null);
  }
  
  // Clean up AR session when done
  void dispose() {
    arSessionManager?.dispose();
  }
}