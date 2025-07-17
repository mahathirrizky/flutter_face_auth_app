import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_face_auth_app/bloc/face_upload/face_upload_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/widgets/camera_preview_widget.dart';

import 'package:toastification/toastification.dart';

class ForceFaceUploadPage extends StatefulWidget {
  const ForceFaceUploadPage({super.key});

  @override
  State<ForceFaceUploadPage> createState() => _ForceFaceUploadPageState();
}

class _ForceFaceUploadPageState extends State<ForceFaceUploadPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showToast('Kamera tidak ditemukan.', type: ToastificationType.error);
        return;
      }
      // Find front camera
      CameraDescription? frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showToast('Gagal menginisialisasi kamera: $e', type: ToastificationType.error);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _showToast(String message, {ToastificationType type = ToastificationType.info}) {
    if (!mounted) return;
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topRight,
    );
  }

  Future<void> _onTakePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showToast('Kamera belum siap.', type: ToastificationType.warning);
      return;
    }
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      if (!mounted) return;
      print('DEBUG: ForceFaceUploadPage - Dispatching UploadFaceImageEvent.');
      context.read<FaceUploadBloc>().add(UploadFaceImageEvent(imageFile: imageFile));
    } catch (e) {
      if (!mounted) return;
      _showToast('Gagal mengambil gambar: $e', type: ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMuted,
      body: BlocListener<FaceUploadBloc, FaceUploadState>(
        listener: (context, state) {
          if (state is FaceUploadSuccess) {
            print('DEBUG: ForceFaceUploadPage - FaceUploadSuccess received. Dispatching FaceRegistrationCompleted.');
            _showToast('Wajah berhasil didaftarkan!', type: ToastificationType.success);
            context.read<AuthBloc>().add(FaceRegistrationCompleted());
          } else if (state is FaceUploadFailure) {
            print('DEBUG: ForceFaceUploadPage - FaceUploadFailure received: ${state.error}');
            _showToast(state.error, type: ToastificationType.error);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Daftarkan Wajah Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textBase),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Untuk melanjutkan dan menggunakan fitur absensi, Anda harus mendaftarkan foto wajah Anda terlebih dahulu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
                const SizedBox(height: 32),
                _buildCameraPreview(),
                const SizedBox(height: 32),
                BlocBuilder<FaceUploadBloc, FaceUploadState>(
                  builder: (context, state) {
                    if (state is FaceUploadInProgress) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton.icon(
                      onPressed: _onTakePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ambil & Unggah Foto'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primary, width: 3.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: (_cameraController != null && _cameraController!.value.isInitialized)
          ? CameraPreviewWidget(controller: _cameraController!)
          : const Center(child: Icon(Icons.camera_enhance, size: 60, color: AppColors.textMuted)),
    );
  }
}

