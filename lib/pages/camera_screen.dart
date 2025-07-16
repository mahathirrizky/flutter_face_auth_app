import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find a front camera if available, otherwise use the first available camera
        CameraDescription selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          selectedCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        _initializeControllerFuture = _controller!.initialize();
      } else {
        _initializeControllerFuture = Future.error('No cameras available');
      }
    } on CameraException catch (e) {
      _initializeControllerFuture = Future.error('Error initializing camera: ${e.description}');
    } catch (e) {
      _initializeControllerFuture = Future.error('An unexpected error occurred: $e');
    }
    if (mounted) {
      setState(() {}); // Trigger rebuild after camera initialization
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Camera Preview'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (_controller != null && _controller!.value.isInitialized) {
              return CameraPreview(_controller!);
            } else {
              return const Center(child: Text('Camera not initialized.'));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}