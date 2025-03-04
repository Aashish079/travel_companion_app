import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket/web_socket.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:travel_companion_app/models/detected_object.dart';
import 'package:travel_companion_app/services/object_detection_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Camera
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  int _frameCount = 0;

  // WebSocket
  WebSocket? _webSocket;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _showChat = false;
  bool _isProcessing = false;

  // Object Detection
  final ObjectDetectionService _objectDetectionService =
      ObjectDetectionService();
  List<DetectedObject> _detectedObjects = [];
  bool _isDetectionEnabled = true;
  bool _showDetectionOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _connectWebSocket();
    _initializeObjectDetection();
  }

  Future<void> _initializeObjectDetection() async {
    await _objectDetectionService.initialize();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    _initializeControllerFuture = _controller?.initialize();

    // Start image stream once camera is initialized
    await _initializeControllerFuture;

    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.startImageStream(_processImageStream);
    }

    if (mounted) setState(() {});
  }

  void _processImageStream(CameraImage image) async {
    // Only process every 10 frames to improve performance
    _frameCount++;
    if (_frameCount % 10 != 0 || !_isDetectionEnabled) return;

    // Process the image with ML Kit
    final objects = await _objectDetectionService.processImage(
        image, _controller!.description, _frameCount);

    if (mounted) {
      setState(() {
        _detectedObjects = objects;
      });
    }
  }

  static String get baseUrl =>
      dotenv.env['CHAT_BASE_URL'] ?? 'ws://192.168.1.24:8000';
  Future<void> _connectWebSocket() async {
    try {
      _webSocket = await WebSocket.connect(
        Uri.parse('$baseUrl/chat'),
      );

      _webSocket?.events.listen(
        (event) async {
          switch (event) {
            case TextDataReceived(text: final text):
              _handleMessage(text);
            case BinaryDataReceived():
              print('Binary data received - not handled');
            case CloseReceived(code: final code, reason: final reason):
              print('WebSocket connection closed: $code [$reason]');
          }
        },
        onError: (error) => print('WebSocket error: $error'),
      );
    } catch (e) {
      print('WebSocket connection error: $e');
    }
  }

  void _handleMessage(String message) {
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
        });
      } else {
        _messages.last['text'] += message;
      }
    });
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

    _webSocket?.sendText(message);
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment:
          message['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message['isUser'] ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: MarkdownBody(
          data: message['text'],
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: message['isUser']
                  ? const Color.fromARGB(255, 38, 157, 147)
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildChatMessage(
                  _messages[_messages.length - 1 - index],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: const Color.fromARGB(255, 148, 20, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Object detection overlay
  Widget _buildDetectionOverlay() {
    return Stack(
      children: [
        // Bounding boxes for detected objects
        ..._detectedObjects.map((object) {
          return Positioned(
            left: object.boundingBox.left,
            top: object.boundingBox.top,
            width: object.boundingBox.width,
            height: object.boundingBox.height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: object.color,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: object.color.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      '${object.label} ${object.confidence}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Build control panel for object detection
  Widget _buildDetectionControls() {
    return _showDetectionOptions
        ? Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Object Detection',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _isDetectionEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isDetectionEnabled = value;
                            if (!value) {
                              _detectedObjects = [];
                            }
                          });
                        },
                        activeColor: const Color.fromARGB(255, 148, 20, 1),
                      ),
                    ],
                  ),
                  Text(
                    'Detected objects: ${_detectedObjects.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showDetectionOptions = true;
                  });
                },
              ),
            ),
          );
  }

  @override
  void dispose() {
    _webSocket?.close();
    _controller?.dispose();
    _messageController.dispose();
    _objectDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                CameraPreview(_controller!),

                // Object detection overlay
                if (_isDetectionEnabled) _buildDetectionOverlay(),

                // Detection controls
                _buildDetectionControls(),

                // Location text
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Mitra Marg',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                // Chat panel if active
                if (_showChat) _buildChatPanel(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Object detection toggle
          FloatingActionButton(
            heroTag: 'detection',
            onPressed: () {
              setState(() {
                _isDetectionEnabled = !_isDetectionEnabled;
                if (!_isDetectionEnabled) {
                  _detectedObjects = [];
                }
              });
            },
            backgroundColor: _isDetectionEnabled
                ? const Color.fromARGB(255, 148, 20, 1)
                : Colors.grey,
            child: Icon(
              _isDetectionEnabled ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // Chat toggle
          FloatingActionButton(
            heroTag: 'chat',
            onPressed: () => setState(() => _showChat = !_showChat),
            backgroundColor: const Color.fromARGB(255, 148, 20, 1),
            child: Icon(
              _showChat ? Icons.close : Icons.chat,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
