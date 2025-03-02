import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ARChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final Offset position;
  final double maxWidth;

  const ARChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.position,
    this.maxWidth = 250,
  }) : super(key: key);

  @override
  State<ARChatBubble> createState() => _ARChatBubbleState();
}

class _ARChatBubbleState extends State<ARChatBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isUser 
                    ? Colors.blue.withOpacity(0.85) 
                    : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: widget.isUser 
                  ? Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    )
                  : MarkdownBody(
                      data: widget.message,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        h1: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}