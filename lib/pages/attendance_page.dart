import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/bloc/attendance/attendance_bloc.dart';
import 'package:flutter_face_auth_app/widgets/camera_preview_widget.dart';
import 'package:toastification/toastification.dart';
import 'package:camera/camera.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

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
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {}); // Rebuild to show the camera preview
        context.read<AttendanceBloc>().add(ActivateCamera(actionType: actionType));
      }
    } catch (e) {
      _showToast('Gagal menginisialisasi kamera: $e', type: ToastificationType.error);
      _disposeCameraController(); // Clean up on error
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
                onPressed: () async {
                  if (_cameraController == null || !_cameraController!.value.isInitialized) {
                    _showToast('Kamera belum siap.', type: ToastificationType.warning);
                    return;
                  }
                  try {
                    final XFile imageFile = await _cameraController!.takePicture();
                    if (!mounted) return;
                    context.read<AttendanceBloc>().add(TakePhotoAndVerifyFace(imageFile: imageFile, actionType: state.currentActionType!));
                  } catch (e) {
                    if (!mounted) return;
                    _showToast('Gagal mengambil gambar: $e', type: ToastificationType.error);
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ambil & Verifikasi'),
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
    final bool isRegularCheckInOpen = isCheckInDone && !isCheckOutDone;
    final bool isOvertimeCheckIn = state.todayAttendance['status'] == 'overtime_in';

    // Get shift start time from employee profile
    final String? shiftStartTimeStr = state.employeeProfile['shift']?['start_time'];
    DateTime? earliestCheckInTime;

    if (shiftStartTimeStr != null) {
      try {
        final now = DateTime.now();
        final List<String> timeParts = shiftStartTimeStr.split(':');
        final int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);

        // Create a DateTime object for today's shift start time
        final DateTime shiftStartToday = DateTime(now.year, now.month, now.day, hour, minute);

        // Calculate earliest allowed check-in time (1.5 hours before shift start)
        earliestCheckInTime = shiftStartToday.subtract(const Duration(minutes: 90));
      } catch (e) {
        print('Error parsing shift start time: $e');
      }
    }

    final bool isTooEarly = earliestCheckInTime != null && DateTime.now().isBefore(earliestCheckInTime);

    final bool canCheckIn = state.isLocationValid && !isCheckInDone && !isOvertimeCheckIn && !isTooEarly; // Cannot check-in if already checked in or in overtime or too early
    final bool canCheckOut = state.isLocationValid && isCheckInDone && !isCheckOutDone && !isOvertimeCheckIn; // Cannot check-out if not checked in or in overtime
    final bool canOvertimeCheckIn = state.isLocationValid && !isRegularCheckInOpen && !isOvertimeCheckIn; // Can only overtime check-in if regular shift is closed and not already in overtime
    final bool canOvertimeCheckOut = state.isLocationValid && isOvertimeCheckIn; // Can only overtime check-out if currently in overtime

    return Card(
      color: AppColors.bgMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Absensi Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textBase)),
            const SizedBox(height: 16),
            _buildInfoRow('Waktu Masuk:', _formatTime(state.todayAttendance['check_in_time'])),
            const SizedBox(height: 8),
            _buildInfoRow('Waktu Pulang:', _formatTime(state.todayAttendance['check_out_time'])),
            const SizedBox(height: 8),
            if (shiftStartTimeStr != null) ...[
              _buildInfoRow('Shift Dimulai:', _formatTime(shiftStartTimeStr)),
              _buildInfoRow('Check-in Paling Awal:', _formatTime(earliestCheckInTime?.toIso8601String())),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:', style: TextStyle(color: AppColors.textBase)),
                Text(state.todayAttendance['status'] ?? '-', style: TextStyle(color: _getStatusColor(state.todayAttendance['status']))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canCheckIn ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: 'check_in')) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textBase,
                      disabledBackgroundColor: AppColors.secondary.withAlpha(100), // Reduced opacity for disabled
                      disabledForegroundColor: AppColors.textBase.withAlpha(100), // Reduced opacity for disabled
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Check-in'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canCheckOut ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: 'check_out')) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.textBase,
                      disabledBackgroundColor: AppColors.secondary.withAlpha(100), // Reduced opacity for disabled
                      disabledForegroundColor: AppColors.textBase.withAlpha(100), // Reduced opacity for disabled
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Check-out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canOvertimeCheckIn ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: 'overtime_in')) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textBase,
                      disabledBackgroundColor: AppColors.accent.withAlpha(100), // Reduced opacity for disabled
                      disabledForegroundColor: AppColors.textBase.withAlpha(100), // Reduced opacity for disabled
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Lembur Masuk'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canOvertimeCheckOut ? () => context.read<AttendanceBloc>().add(ActivateCamera(actionType: 'overtime_out')) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textBase,
                      disabledBackgroundColor: AppColors.accent.withAlpha(100), // Reduced opacity for disabled
                      disabledForegroundColor: AppColors.textBase.withAlpha(100), // Reduced opacity for disabled
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Lembur Pulang'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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