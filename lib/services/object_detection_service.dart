import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:travel_companion_app/models/detected_object.dart' as app_model;

class ObjectDetectionService {
  // ML Kit Object Detector
  ObjectDetector? _objectDetector;

  // Configuration and options
  bool _canProcess = false;
  bool _isBusy = false;

  // We'll use this to avoid redundant processing frames
  int _lastProcessedFrameNumber = -1;

  // Create a singleton for the service
  static final ObjectDetectionService _instance =
      ObjectDetectionService._internal();

  factory ObjectDetectionService() => _instance;

  ObjectDetectionService._internal();

  Future<void> initialize() async {
    // Only initialize once
    if (_objectDetector != null) return;

    try {
      // Try to locate the model file
      final modelPath = await _getModel('assets/ml/object_labeler.tflite');

      // Configure the detector
      final options = LocalObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
        modelPath: modelPath,
      );

      _objectDetector = ObjectDetector(options: options);
      _canProcess = true;
      debugPrint('🔍 Object detection initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize object detection: $e');
      _canProcess = false;
    }
  }

  Future<String> _getModel(String assetPath) async {
    // Get the app's document directory
    final appDir = await getApplicationDocumentsDirectory();

    // Get the filename from the asset path
    final fileName = p.basename(assetPath);

    // Create a new file path in the app's document directory
    final modelPath = p.join(appDir.path, fileName);
    final modelFile = File(modelPath);

    // Check if the model file already exists
    if (!await modelFile.exists()) {
      // If the model doesn't exist, copy it from the assets
      final byteData = await rootBundle.load(assetPath);
      await modelFile.writeAsBytes(byteData.buffer.asUint8List());
    }

    return modelPath;
  }

  Future<List<app_model.DetectedObject>> processImage(
      CameraImage image, CameraDescription camera, int frameNumber) async {
    // Check if we can process this frame
    if (!_canProcess || _isBusy || frameNumber == _lastProcessedFrameNumber) {
      return [];
    }

    _isBusy = true;
    _lastProcessedFrameNumber = frameNumber;

    try {
      // Convert the CameraImage to an InputImage
      final inputImage = await _cameraImageToInputImage(image, camera);
      if (inputImage == null) {
        _isBusy = false;
        return [];
      }

      // Process the image and get detected objects
      final objects = await _objectDetector!.processImage(inputImage);

      // Convert ML Kit objects to our app's model
      final detectedObjects = <app_model.DetectedObject>[];
      for (var i = 0; i < objects.length; i++) {
        detectedObjects
            .add(app_model.DetectedObject.fromMlKitObject(objects[i], i));
      }

      _isBusy = false;
      return detectedObjects;
    } catch (e) {
      _isBusy = false;
      debugPrint('❌ Error processing image: $e');
      return [];
    }
  }

  Future<InputImage?> _cameraImageToInputImage(
      CameraImage cameraImage, CameraDescription camera) async {
    // Get image rotation
    final rotation = InputImageRotationValue.fromRawValue(
      (camera.sensorOrientation / 90).round() * 90,
    );

    if (rotation == null) return null;

    // Get image format
    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // Android format processing
    if (Platform.isAndroid) {
      final bytes = cameraImage.planes[0].bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size:
              Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: cameraImage.planes[0].bytesPerRow,
        ),
      );
    }
    // iOS format processing
    else if (Platform.isIOS) {
      final allBytes = WriteBuffer();
      for (final plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      return InputImage.fromBytes(
        bytes: allBytes.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size:
              Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: cameraImage.planes[0].bytesPerRow,
        ),
      );
    }

    return null;
  }

  void dispose() {
    _canProcess = false;
    _objectDetector?.close();
  }
}
