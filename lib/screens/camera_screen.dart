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
  List<Detection> _detections = [];
  Size? _imageSize;

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

      // Add detection results to chat
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
          _showChat = true;
        });
      } else {
        setState(() {
          _messages.add({
            'text': "No monuments detected in this image.",
            'isUser': false,
            'isComplete': true,
          });
          _showChat = true;
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
        _showChat = true;
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
    _webSocket?.close();
    _controller?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera preview
                CameraPreview(_controller!),

                // Detection overlays
                if (_detections.isNotEmpty && _imageSize != null)
                  CustomPaint(
                    size: screenSize,
                    painter: DetectionOverlayPainter(
                      detections: _detections,
                      imageSize: _imageSize!,
                      screenSize: screenSize,
                    ),
                  ),

                // Location indicator
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    'Mitra Marg',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),

                // Loading indicator for detection
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

                // Chat panel
                if (_showChat) _buildChatPanel(),

                // Detection button
                Positioned(
                  bottom: 20,
                  right: 80,
                  child: FloatingActionButton(
                    onPressed: _detectMonuments,
                    backgroundColor: const Color.fromARGB(255, 148, 20, 1),
                    child: const Icon(
                      Icons.camera,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showChat = !_showChat),
        backgroundColor: const Color.fromARGB(255, 148, 20, 1),
        child: Icon(
          _showChat ? Icons.close : Icons.chat,
          color: const Color.fromARGB(255, 251, 252, 252),
        ),
      ),
    );
  }
}
