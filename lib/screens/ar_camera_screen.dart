import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:flutter/material.dart';
import 'package:travel_companion_app/services/ar_manager.dart';

class ARCameraScreen extends StatefulWidget {
  const ARCameraScreen({Key? key}) : super(key: key);

  @override
  State<ARCameraScreen> createState() => _ARCameraScreenState();
}

class _ARCameraScreenState extends State<ARCameraScreen> {
  final ARManager arManager = ARManager();
  bool _showChat = false;
  String? _currentLandmark;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isProcessing = false;
  
  @override
  void dispose() {
    arManager.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  // UI for AR chat message bubbles
  Widget _buildARChatMessage(Map<String, dynamic> message, Offset position) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message['isUser'] 
            ? Colors.blue.withOpacity(0.8) 
            : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          message['text'],
          style: TextStyle(
            color: message['isUser'] ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
  
  // Calculate screen position from AR world position
  Offset _calculateScreenPosition(Matrix4 transformationMatrix) {
    // This is a simplified version - would need actual AR-to-screen
    // coordinate transformation in a production app
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Return a position in the center for now
    // In a real implementation, this would use the actual matrix math
    return Offset(screenWidth * 0.5, screenHeight * 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (arSessionManager, arObjectManager, 
                arAnchorManager, arLocationManager) {
              arManager.arSessionManager = arSessionManager;
              arManager.arObjectManager = arObjectManager;
              arManager.arAnchorManager = arAnchorManager;
              arManager.arLocationManager = arLocationManager;
              
              arManager.initializeAR();
            },
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          
          // Location indicator
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _currentLandmark ?? 'Scanning...',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          // AR Chat Messages
          if (_showChat)
            for (var message in _messages)
              _buildARChatMessage(
                message, 
                _calculateScreenPosition(
                  arManager.recognizedObjects[_currentLandmark] ?? Matrix4.identity()
                )
              ),
          
          // Chat input
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
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildARFloatingButton(),
    );
  }
  
  Widget _buildARFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => setState(() => _showChat = !_showChat),
        backgroundColor: Colors.blue,
        child: Icon(_showChat ? Icons.close : Icons.chat),
      ),
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
      });
      _isProcessing = true;
    });
    
    // Simulated response - would connect to WebSocket in real implementation
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          'text': "This is the historic Durbar Square, built in the 17th century. It features Newari architecture and was designated as a UNESCO World Heritage site in 1979.",
          'isUser': false,
          'isComplete': true,
        });
        _isProcessing = false;
      });
    });
  }
}