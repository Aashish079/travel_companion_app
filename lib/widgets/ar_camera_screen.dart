import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter/material.dart';
import 'package:travel_companion_app/services/ar_chat_service.dart';
import 'package:travel_companion_app/services/landmark_recognition_service.dart';
import 'package:travel_companion_app/widgets/ar_chat_bubble.dart';
import 'package:travel_companion_app/widgets/ar_chat_button.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({super.key});

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;
  
  final LandmarkRecognitionService _landmarkService = LandmarkRecognitionService();
  final ARChatService _chatService = ARChatService();
  
  String? _currentLandmark;
  final List<Map<String, dynamic>> _arAnchors = [];
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  
  bool _showChat = false;
  bool _isProcessing = false;
  
  // For positioning AR elements
  final Map<String, Offset> _arPositions = {
    'default': Offset(150, 200), // Default position if no detection available
  };

  @override
  void initState() {
    super.initState();
    
    _landmarkService.landmarkStream.listen((landmarkData) {
      setState(() {
        _currentLandmark = landmarkData['name'];
        _addLandmarkAnchor(landmarkData);
      });
    });
    
    _chatService.onMessageReceived = _handleIncomingMessage;
    _chatService.connect();
    
    // Start simulated landmark detection (in a real app, this would use ML vision)
    Future.delayed(const Duration(seconds: 3), () {
      _simulateDetectLandmark();
    });
  }
  
  // Simulated landmark detection for demo purposes
  void _simulateDetectLandmark() {
    setState(() {
      _currentLandmark = 'Patan Durbar Square';
      // Add position for the landmark-specific chat button
      _arPositions['Patan Durbar Square'] = Offset(
        MediaQuery.of(context).size.width * 0.7,
        MediaQuery.of(context).size.height * 0.4,
      );
    });
  }
  
  // Add an AR anchor for a detected landmark
  void _addLandmarkAnchor(Map<String, dynamic> landmarkData) {
    if (arObjectManager == null) return;
    
    // In a real implementation, this would use actual AR anchor positioning
    final screenSize = MediaQuery.of(context).size;
    final position = _arPositions[landmarkData['name']] ?? _arPositions['default']!;
    
    setState(() {
      _arAnchors.add({
        'name': landmarkData['name'],
        'position': position,
        'info': landmarkData['description'],
      });
    });
  }
  
  // Handle incoming message from WebSocket
  void _handleIncomingMessage(String message) {
    if (message == '[DONE]') {
      setState(() => _isProcessing = false);
      return;
    }

    setState(() {
      if (_messages.isEmpty || _messages.last['isUser'] == true) {
        _messages.add({
          'text': message,
          'isUser': false,
          'isComplete': false,
          'position': _calculateMessagePosition(false),
        });
      } else {
        _messages.last['text'] += message;
      }
    });
  }
  
  // Calculate position for message bubbles in AR space
  Offset _calculateMessagePosition(bool isUser) {
    // In a real AR implementation, this would calculate 3D space position
    // For demo, we're using screen positions with some spacing logic
    final screenSize = MediaQuery.of(context).size;
    final landmarkPosition = _arPositions[_currentLandmark] ?? _arPositions['default']!;
    
    // Position user messages to the right, AI messages to the left
    return isUser 
        ? Offset(
            landmarkPosition.dx + 30,
            landmarkPosition.dy - 70,
          ) 
        : Offset(
            landmarkPosition.dx - 250,
            landmarkPosition.dy - 70,
          );
  }
  
  void _sendMessage() {
    if (_messageController.text.isEmpty || _isProcessing) return;

    final message = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'isComplete': true,
        'position': _calculateMessagePosition(true),
      });
      _isProcessing = true;
    });

    _chatService.sendMessage(message, landmarkContext: _currentLandmark);
  }
  
  // Method to toggle AR chat visibility
  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });
  }
  
  @override
  void dispose() {
    arSessionManager?.dispose();
    _chatService.close();
    _landmarkService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // AR View
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          
          // Landmark identification info
          if (_currentLandmark != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _currentLandmark!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          // AR Chat Button for the landmark
          if (_currentLandmark != null && _arPositions.containsKey(_currentLandmark))
            ARChatButton(
              onPressed: _toggleChat,
              isVisible: !_showChat,
              position: _arPositions[_currentLandmark]!,
              landmarkName: _currentLandmark!,
            ),
          
          // AR Chat Messages
          if (_showChat)
            ..._messages.map((message) => ARChatBubble(
              message: message['text'],
              isUser: message['isUser'],
              position: message['position'],
            )),
          
          // Chat input field
          if (_showChat)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask about this place...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: const Color(0xff1565c0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Hide the floating action button when chat is open
      floatingActionButton: _showChat ? null : FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat),
      ),
    );
  }
  
  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;
    
    this.arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: true,
      handlePans: true,
      handleRotation: true,
    );
    
    this.arObjectManager!.onInitialize();
    
    // Configure to detect planes - Fixed the type error by adding a handler method
    this.arSessionManager!.onPlaneOrPointTap(_onPlaneOrPointTapHandler as List<ARHitTestResult>);
  }
  
  // Handler method with the correct signature for onPlaneOrPointTap
  void _onPlaneOrPointTapHandler(List<ARHitTestResult> hitTestResults) {
    // Call the async method without awaiting it
    onPlaneOrPointTapped(hitTestResults);
  }
  
  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) return;
    
    // Get the first hit test result
    final hit = hitTestResults.firstWhere(
      (hitTest) => hitTest.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );
    
    // Update position for current landmark if available
    if (_currentLandmark != null) {
      // In a real app, this would convert 3D coordinates to screen space
      // For demo, we'll simulate this with screen coordinates
      final screenSize = MediaQuery.of(context).size;
      
      setState(() {
        _arPositions[_currentLandmark!] = Offset(
          screenSize.width * 0.5,
          screenSize.height * 0.4,
        );
      });
    }
  }
}