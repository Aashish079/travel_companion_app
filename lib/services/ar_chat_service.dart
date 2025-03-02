import 'package:web_socket/web_socket.dart';

class ARChatService {
  WebSocket? _webSocket;
  Function(String)? onMessageReceived;
  
  Future<void> connect() async {
    try {
      _webSocket = await WebSocket.connect(
        Uri.parse('ws://192.168.1.66:8000/chat'),
      );
      
      _webSocket?.events.listen(
        (event) async {
          switch (event) {
            case TextDataReceived(text: final text):
              if (onMessageReceived != null) {
                onMessageReceived!(text);
              }
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
      // In case of connection error, provide simulated responses
      _setupSimulatedResponses();
    }
  }
  
  void _setupSimulatedResponses() {
    // For demo purposes, simulate responses when connection fails
    onMessageReceived ??= (_) {};
  }
  
  void sendMessage(String message, {String? landmarkContext}) {
    if (_webSocket == null) {
      _simulateResponse(message, landmarkContext);
      return;
    }
    
    final contextEnhancedMessage = landmarkContext != null
        ? '{"message": "$message", "context": "$landmarkContext"}'
        : message;
        
    _webSocket?.sendText(contextEnhancedMessage);
  }
  
  void _simulateResponse(String message, String? landmarkContext) {
    // Simulate AI response based on the landmark context
    Future.delayed(const Duration(milliseconds: 500), () {
      String response = "I don't have information about this location yet.";
      
      if (landmarkContext == 'Patan Durbar Square') {
        if (message.toLowerCase().contains('history')) {
          response = "Patan Durbar Square is located at the center of the city of Lalitpur in Nepal. It is one of three Durbar Squares in the Kathmandu Valley, all of which are UNESCO World Heritage Sites. It was built primarily during the Malla period in the 16th and 17th centuries.";
        } else if (message.toLowerCase().contains('visit') || message.toLowerCase().contains('time')) {
          response = "The best time to visit Patan Durbar Square is early morning or late afternoon to avoid crowds. The site is open daily from 7am to 7pm. The entrance fee for foreign visitors is approximately NPR 1000.";
        } else {
          response = "Patan Durbar Square showcases the architectural beauty of the Newari civilization. Key attractions include the Royal Palace, Krishna Mandir, Bhimsen Temple, and numerous intricately carved temples and statues.";
        }
      }
      
      onMessageReceived!(response);
      Future.delayed(const Duration(milliseconds: 100), () {
        onMessageReceived!('[DONE]');
      });
    });
  }
  
  void close() {
    _webSocket?.close();
  }
}