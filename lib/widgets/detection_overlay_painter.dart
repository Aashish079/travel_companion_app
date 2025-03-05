import 'package:flutter/material.dart';
import 'package:travel_companion_app/services/monument_detection_service.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;
  final Size screenSize;

  DetectionOverlayPainter({
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint textBackgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Calculate scale factors
    double scaleX = screenSize.width / imageSize.width;
    double scaleY = screenSize.height / imageSize.height;

    for (var detection in detections) {
      // Scale bounding box to screen dimensions
      double left = detection.bbox[0] * scaleX;
      double top = detection.bbox[1] * scaleY;
      double right = detection.bbox[2] * scaleX;
      double bottom = detection.bbox[3] * scaleY;

      // Draw the bounding box
      final Rect rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, boxPaint);

      // Prepare text for the label
      final String landmarkName = detection.landmark
          .split('_')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
      final String confidenceText = '${(detection.confidence * 100).toInt()}%';
      final String labelText = '$landmarkName ($confidenceText)';

      // Configure text style
      const TextStyle textStyle = TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

      // Create text painter
      final textPainter = TextPainter(
        text: TextSpan(text: labelText, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw text background
      final textBackgroundRect = Rect.fromLTWH(
        left,
        top - textPainter.height - 8,
        textPainter.width + 16,
        textPainter.height + 8,
      );
      canvas.drawRect(textBackgroundRect, textBackgroundPaint);

      // Draw the text
      textPainter.paint(canvas, Offset(left + 8, top - textPainter.height - 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
