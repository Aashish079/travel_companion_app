import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket/web_socket.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  Future<void> _connectWebSocket() async {
    try {
      _webSocket = await WebSocket.connect(
        Uri.parse('ws://192.168.1.66:8000/chat'),
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
              color: message['isUser'] ? Colors.blue[800] : Colors.black,
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
                    color: Colors.blue,
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
    return Scaffold(
      // body: Text('Camera Screen'),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller!),
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
                if (_showChat) _buildChatPanel(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showChat = !_showChat),
        backgroundColor: Colors.blue,
        child: Icon(_showChat ? Icons.close : Icons.chat),
      ),
    );
  }
}