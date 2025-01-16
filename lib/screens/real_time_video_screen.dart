import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class RealTimeVideoScreen extends StatefulWidget {
  @override
  _RealTimeVideoScreenState createState() => _RealTimeVideoScreenState();
}

class _RealTimeVideoScreenState extends State<RealTimeVideoScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![0],
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
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
        ],
      ),
    );
  }
}
