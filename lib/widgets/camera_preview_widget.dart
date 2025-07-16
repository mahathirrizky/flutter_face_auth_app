import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Check if the controller is initialized before building the preview.
    if (!controller.value.isInitialized) {
      // Return a loading indicator if not initialized.
      return const Center(child: CircularProgressIndicator());
    }
    // Return the actual camera preview.
    return CameraPreview(controller);
  }
}