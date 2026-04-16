import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/bloc/attendance/attendance_bloc.dart';
import 'package:flutter_face_auth_app/widgets/camera_preview_widget.dart';
import 'package:toastification/toastification.dart';
import 'package:camera/camera.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      minFaceSize: 0.15,
    ),
  );
  bool _isDetecting = false;
  bool _blinkReady = false;
  int _faceNotFoundCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeCameraDescriptions();
    context.read<AttendanceBloc>().add(FetchInitialData());
  }

  Future<void> _initializeCameraDescriptions() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      _showToast('Gagal memuat kamera: $e', type: ToastificationType.error);
    }
  }

  Future<void> _initializeCameraController(String actionType) async {
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
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {}); // Rebuild to show the camera preview
        context.read<AttendanceBloc>().add(ActivateCamera(actionType: actionType));

        _cameraController!.startImageStream((CameraImage image) {
          if (_isDetecting) return;
          _isDetecting = true;
          _processCameraImage(image, actionType);
        });
      }
    } catch (e) {
      _showToast('Gagal menginisialisasi kamera: $e', type: ToastificationType.error);
      _disposeCameraController(); // Clean up on error
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameras!.firstWhere((c) => c.lensDirection == _cameraController!.description.lensDirection);
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21)) return null;

    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image, String actionType) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;
      
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        _faceNotFoundCounter = 0;
        final face = faces.first;
        if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
          final double leftProb = face.leftEyeOpenProbability!;
          final double rightProb = face.rightEyeOpenProbability!;
          
          if (leftProb > 0.8 && rightProb > 0.8) {
            _blinkReady = true;
          } else if (leftProb < 0.2 && rightProb < 0.2 && _blinkReady) {
            _blinkReady = false;
            await _cameraController!.stopImageStream();
            final XFile imageFile = await _cameraController!.takePicture();
            if (mounted) {
               _showToast('Kedipan terdeteksi!', type: ToastificationType.success);
               context.read<AttendanceBloc>().add(TakePhotoAndVerifyFace(
                   imageFile: imageFile, 
                   actionType: actionType,
               ));
            }
          }
        }
      } else {
        _faceNotFoundCounter++;
        if (_faceNotFoundCounter > 30) {
           _blinkReady = false; 
        }
      }
    } catch(e) {
      // ignore
    } finally {
      if (mounted) {
         setState(() { _isDetecting = false; });
      } else {
         _isDetecting = false;
      }
    }
  }

  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {}); // Rebuild to remove the camera preview
      }
    }
  }

  @override
  void dispose() {
    _disposeCameraController();
    _faceDetector.close();
    super.dispose();
  }

  void _showToast(String message, {ToastificationType type = ToastificationType.info}) {
    if (!mounted) return;
    Color textColor = AppColors.textBase; // Default color
    if (type == ToastificationType.error) {
      textColor = Colors.red;
    } else if (type == ToastificationType.success) {
      textColor = Colors.green; // Set to green for success
    }

    toastification.show(
      context: context,
      title: Text(message, style: TextStyle(color: textColor)), // Apply text color
      type: type,
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topRight,
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    try {
      // If it's a full ISO string, parse it directly
      if (timeString.contains('T')) {
        final dateTime = DateTime.parse(timeString).toLocal();
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else { // Assume it's HH:MM:SS format
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          // Create a dummy DateTime for formatting
          final dummyDateTime = DateTime(2000, 1, 1, hour, minute);
          return '${dummyDateTime.hour.toString().padLeft(2, '0')}:${dummyDateTime.minute.toString().padLeft(2, '0')}';
        }
      }
      return 'Invalid Time';
    } catch (e) {
      print('Error formatting time: $e');
      return 'Invalid Time';
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--/--/----';
     try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'on_time':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'early_leave':
        return Colors.yellow;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        backgroundColor: AppColors.bgMuted,
        foregroundColor: AppColors.textBase,
        elevation: 0,
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceLoaded) {
            // Handle camera activation/deactivation
            if (state.isCameraActive && _cameraController == null) {
              // This check is to prevent re-initializing if already active
              _initializeCameraController(state.currentActionType!);
            } else if (!state.isCameraActive && _cameraController != null) {
              _disposeCameraController();
            }

            // Handle toasts
            if (state.errorMessage != null) {
              _showToast(state.errorMessage!, type: ToastificationType.error);
            }
            if (state.faceRecognitionStatus.contains('gagal')) {
               _showToast(state.faceRecognitionStatus, type: ToastificationType.error);
            }
            if (state.faceRecognitionStatus.contains('terverifikasi')) {
               _showToast(state.faceRecognitionStatus, type: ToastificationType.success);
            }
          } else if (state is AttendanceError) {
            _showToast(state.message, type: ToastificationType.error);
          }
        },
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.secondary,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(state.message, style: TextStyle(color: AppColors.textBase)),
                  ],
                ),
              );
            }
            if (state is AttendanceLoaded) {
              return _buildAttendanceLoadedView(context, state);
            }
            if (state is AttendanceError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AttendanceBloc>().add(FetchInitialData()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Halaman Absensi'));
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceLoadedView(BuildContext context, AttendanceLoaded state) {
    final bool isCheckInDone = state.todayAttendance['check_in_time'] != null && state.todayAttendance['check_in_time'].isNotEmpty;
    final bool isCheckOutDone = state.todayAttendance['check_out_time'] != null && state.todayAttendance['check_out_time'].isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildValidationCard(context, state),
          const SizedBox(height: 16),
          _buildTodayAttendanceCard(context, state, isCheckInDone, isCheckOutDone),
           _buildAttendanceHistoryCard(
            context,
            state.attendanceHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCard(BuildContext context, AttendanceLoaded state) {
    return Card(
      color: AppColors.bgMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Validasi & Verifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBase)),
            const SizedBox(height: 16),
            _buildStatusRow('Status Lokasi:', state.locationStatus, state.isLocationValid),
            const SizedBox(height: 8),
            _buildStatusRow('Status Wajah:', state.faceRecognitionStatus, state.isFaceRecognized),
            const SizedBox(height: 16),
            _buildCameraSection(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection(BuildContext context, AttendanceLoaded state) {
    return Container(
      width: 400,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.accent, width: 3.0), // Bingkai yang lebih menonjol
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(

            height: 250, // Tinggi konsisten
            child: (state.isCameraActive && _cameraController != null && _cameraController!.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: 4 / 5,
                    child: CameraPreviewWidget(controller: _cameraController!),
                  )
                : Center(child: Icon(Icons.camera_enhance, size: 60, color: AppColors.textMuted)),
          ),
          
          if (state.isCameraActive)
              Positioned(
              bottom: 10,
              child: ElevatedButton.icon(
                onPressed: () {
                   _showToast('Mohon berkedip untuk absen.', type: ToastificationType.info);
                },
                icon: const Icon(Icons.face),
                label: const Text('Tunggu Kedipan Mata...'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textBase,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceCard(BuildContext context, AttendanceLoaded state, bool isCheckInDone, bool isCheckOutDone) {
    final bool isNoonCheckDone = state.todayAttendance['noon_check_time'] != null && state.todayAttendance['noon_check_time'].toString().isNotEmpty;
    final bool isOvertimeCheckIn = state.todayAttendance['status']?.toString().contains('overtime') ?? false;

    // Get shift windows
    final String? shiftStart = state.employeeProfile['shift']?['start_time'];
    final String? noonStart = state.employeeProfile['shift']?['noon_start_time'];
    final String? noonEnd = state.employeeProfile['shift']?['noon_end_time'];
    final bool hasNoonCheck = noonStart != null && noonStart.isNotEmpty;

    // Determine current window (Client-side estimation)
    final now = DateTime.now();
    DateTime? windowNoonStart;
    DateTime? windowNoonEnd;

    if (hasNoonCheck) {
      final partsS = noonStart.split(':');
      final partsE = noonEnd!.split(':');
      windowNoonStart = DateTime(now.year, now.month, now.day, int.parse(partsS[0]), int.parse(partsS[1]));
      windowNoonEnd = DateTime(now.year, now.month, now.day, int.parse(partsE[0]), int.parse(partsE[1]));
    }

    String primaryButtonLabel = 'Check-in';
    String actionType = 'check_in';
    bool canTakeAction = state.isLocationValid;

    if (hasNoonCheck) {
      if (now.isBefore(windowNoonStart!)) {
        primaryButtonLabel = 'Absen Pagi';
        canTakeAction &= !isCheckInDone;
      } else if (now.isAfter(windowNoonStart) && now.isBefore(windowNoonEnd!)) {
        primaryButtonLabel = 'Absen Siang';
        canTakeAction &= !isNoonCheckDone;
      } else {
        primaryButtonLabel = 'Absen Pulang';
        canTakeAction &= (isCheckInDone || isNoonCheckDone) && !isCheckOutDone;
      }
    } else {
      // Fallback 2-stage
      if (!isCheckInDone) {
        primaryButtonLabel = 'Check-in';
      } else {
        primaryButtonLabel = 'Check-out';
        canTakeAction &= !isCheckOutDone;
      }
    }

    return Card(
      color: AppColors.bgMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Absensi Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBase)),
                if (isOvertimeCheckIn)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
                     child: Text('LEMBUR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.bgBase)),
                   ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Triple-Check Status Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStageIcon('Pagi', isCheckInDone, state.todayAttendance['check_in_time']),
                if (hasNoonCheck) _buildStageIcon('Siang', isNoonCheckDone, state.todayAttendance['noon_check_time']),
                _buildStageIcon('Pulang', isCheckOutDone, state.todayAttendance['check_out_time']),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main Contextual Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canTakeAction ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: actionType)) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textBase,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(primaryButtonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Overtime Actions (Subtle)
            if (!isOvertimeCheckIn)
              Center(
                child: TextButton(
                  onPressed: state.isLocationValid ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: 'overtime_in')) : null,
                  child: Text('Mulai Lembur?', style: TextStyle(color: AppColors.accent)),
                ),
              )
            else
              Center(
                child: TextButton(
                  onPressed: state.isLocationValid ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: 'overtime_out')) : null,
                  child: const Text('Selesaikan Lembur', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIcon(String label, bool isDone, dynamic time) {
    return Column(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? Colors.greenAccent : AppColors.textMuted,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textBase, fontWeight: FontWeight.bold)),
        Text(
          isDone ? _formatTime(time.toString()) : '--:--',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistoryCard(BuildContext context, List<Map<String, dynamic>> history) {
    return Card(
      color: AppColors.bgMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Absensi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBase)),
            const SizedBox(height: 8),
            if (history.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_formatDate(record['check_in_time']), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textBase)),
                    subtitle: Text(
                      'Masuk: ${_formatTime(record['check_in_time'])} - Pulang: ${_formatTime(record['check_out_time'])}',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: Text(record['status'] ?? '-', style: TextStyle(color: _getStatusColor(record['status']))),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              )
            else
              Text('Tidak ada riwayat absensi.', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isValid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textBase)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: isValid ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textBase)),
        Text(value, style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}