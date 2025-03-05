import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket/web_socket.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:travel_companion_app/services/monument_detection_service.dart';
import 'package:travel_companion_app/widgets/detection_overlay_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  WebSocket? _webSocket;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _showChat = false;
  bool _isProcessing = false;
  bool _isDetecting = false;
  bool _continuousDetectionEnabled = false;
  List<Detection> _detections = [];
  Size? _imageSize;
  bool _processingFrame = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _connectWebSocket();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller?.initialize();
    if (mounted) setState(() {});
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

  void _toggleContinuousDetection() {
    setState(() {
      _continuousDetectionEnabled = !_continuousDetectionEnabled;

      if (_continuousDetectionEnabled) {
        // Start continuous detection
        _startContinuousDetection();
      } else {
        // Clear current detections when turned off
        _detections = [];
      }
    });
  }

  Future<void> _startContinuousDetection() async {
    if (!_continuousDetectionEnabled ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    // Process a single frame if not already processing
    if (!_processingFrame) {
      await _processFrame();
    }

    // Schedule next frame capture if continuous detection is still enabled
    if (_continuousDetectionEnabled) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _continuousDetectionEnabled) {
          _startContinuousDetection();
        }
      });
    }
  }

  Future<void> _processFrame() async {
    if (_processingFrame ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    _processingFrame = true;
    try {
      // Capture image
      final XFile image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Get image dimensions (only if we don't have them yet)
      if (_imageSize == null) {
        final imageInfo = await decodeImageFromList(imageBytes);
        _imageSize =
            Size(imageInfo.width.toDouble(), imageInfo.height.toDouble());
      }

      // Send to API for detection
      final detectionResponse =
          await MonumentDetectionService.detectMonument(imageBytes);

      // Update UI with results if still in continuous mode
      if (_continuousDetectionEnabled && mounted) {
        setState(() {
          _detections = detectionResponse.detections;
        });

        // Add to chat messages without showing chat
        if (_detections.isNotEmpty) {
          final detectionSummary = _detections
              .map((d) =>
                  '- ${d.landmark.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')} (${(d.confidence * 100).toInt()}%)')
              .join('\n');

          if (mounted) {
            setState(() {
              // Replace the last message if it exists, otherwise add new
              if (_messages.isNotEmpty && !_messages.last['isUser']) {
                _messages.last = {
                  'text': "Latest detection:\n$detectionSummary",
                  'isUser': false,
                  'isComplete': true,
                };
              } else {
                _messages.add({
                  'text': "Latest detection:\n$detectionSummary",
                  'isUser': false,
                  'isComplete': true,
                });
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error during continuous detection: $e');
      // Don't stop continuous detection on error, just log it
    } finally {
      _processingFrame = false;
    }
  }

  // Single detection for manual button press
  Future<void> _detectMonuments() async {
    if (_isDetecting ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isDetecting = true;
      _detections = [];
    });

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Get image dimensions
      final imageInfo = await decodeImageFromList(imageBytes);
      _imageSize =
          Size(imageInfo.width.toDouble(), imageInfo.height.toDouble());

      // Send to API for detection
      final detectionResponse =
          await MonumentDetectionService.detectMonument(imageBytes);

      // Update UI with results
      setState(() {
        _detections = detectionResponse.detections;
        _isDetecting = false;
      });

      // Store detection results in messages but don't show chat automatically
      if (_detections.isNotEmpty) {
        final detectionSummary = _detections
            .map((d) =>
                '- ${d.landmark.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')} (${(d.confidence * 100).toInt()}%)')
            .join('\n');

        setState(() {
          _messages.add({
            'text': "I detected the following monuments:\n$detectionSummary",
            'isUser': false,
            'isComplete': true,
          });
        });
      } else {
        setState(() {
          _messages.add({
            'text': "No monuments detected in this image.",
            'isUser': false,
            'isComplete': true,
          });
        });
      }
    } catch (e) {
      print('Error during detection: $e');
      setState(() {
        _isDetecting = false;
        _messages.add({
          'text': "Error during detection: $e",
          'isUser': false,
          'isComplete': true,
        });
      });
    }
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

  @override
  void dispose() {
    // Make sure to turn off continuous detection when leaving the screen
    _continuousDetectionEnabled = false;
    _webSocket?.close();
    _controller?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Get the height of the bottom navigation bar
    const double bottomNavHeight = kBottomNavigationBarHeight;

    return Scaffold(
      // Remove the default body padding/margin that creates the white strip
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera preview - Fills the entire available space
                SizedBox.expand(
                  child: CameraPreview(_controller!),
                ),

                // Detection overlays with real-time bounding boxes and labels
                if (_detections.isNotEmpty && _imageSize != null)
                  CustomPaint(
                    size: screenSize,
                    painter: DetectionOverlayPainter(
                      detections: _detections,
                      imageSize: _imageSize!,
                      screenSize: screenSize,
                    ),
                  ),

                // Continuous detection indicator
                if (_continuousDetectionEnabled)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Location indicator - positioned directly above action buttons
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
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

                // Loading indicator for single detection
                if (_isDetecting)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Detecting monuments...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Chat panel (only shown when user explicitly opens it)
                if (_showChat) _buildChatPanel(),

                // Row of action buttons at the bottom - positioned to be above the bottom nav
                Positioned(
                  bottom: 20, // Space above the bottom navigation
                  right: 20,
                  left: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Continuous detection toggle button
                      FloatingActionButton.small(
                        heroTag: "continuousBtn",
                        onPressed: _toggleContinuousDetection,
                        backgroundColor: _continuousDetectionEnabled
                            ? Colors.red
                            : Colors.black54,
                        child: Icon(
                          _continuousDetectionEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      // Single detection button - centered and prominent
                      FloatingActionButton(
                        heroTag: "detectBtn",
                        onPressed: _continuousDetectionEnabled
                            ? null
                            : _detectMonuments,
                        backgroundColor: _continuousDetectionEnabled
                            ? Colors.grey
                            : const Color.fromARGB(255, 148, 20, 1),
                        child: const Icon(
                          Icons.camera,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      // Chat toggle button
                      FloatingActionButton.small(
                        heroTag: "chatBtn",
                        onPressed: () => setState(() => _showChat = !_showChat),
                        backgroundColor: Colors.black54,
                        child: Icon(
                          _showChat ? Icons.close : Icons.chat,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      // Remove any additional padding
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
    );
  }
}