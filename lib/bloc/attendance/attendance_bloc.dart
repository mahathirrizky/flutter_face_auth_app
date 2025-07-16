import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_face_auth_app/repositories/attendance_repository.dart';
import 'package:flutter_face_auth_app/repositories/profile_repository.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:meta/meta.dart';
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final ProfileRepository _profileRepository;
  final AttendanceRepository _attendanceRepository;
  StreamSubscription<Position>? _positionStreamSubscription;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  AttendanceBloc({
    required ProfileRepository profileRepository,
    required AttendanceRepository attendanceRepository,
  })  : _profileRepository = profileRepository,
        _attendanceRepository = attendanceRepository,
        super(AttendanceInitial()) {
    on<FetchInitialData>(_onFetchInitialData);
    on<UpdateDeviceLocation>(_onUpdateDeviceLocation);
    on<TakePhotoAndVerifyFace>(_onTakePhotoAndVerifyFace); // This will be our main action trigger
    on<StartLocationUpdates>(_onStartLocationUpdates);
    on<StopLocationUpdates>(_onStopLocationUpdates);
    on<ActivateCamera>(_onActivateCamera);
    on<DeactivateCamera>(_onDeactivateCamera);
  }

  // ... (keep _onActivateCamera, _onDeactivateCamera, _onFetchInitialData, _onUpdateDeviceLocation, _onStartLocationUpdates, _onStopLocationUpdates, close, and _haversineDistance methods as they are)
  void _onActivateCamera(ActivateCamera event, Emitter<AttendanceState> emit) {
    if (state is AttendanceLoaded) {
      final currentState = state as AttendanceLoaded;
      emit(currentState.copyWith(isCameraActive: true, currentActionType: event.actionType));
    }
  }

  void _onDeactivateCamera(DeactivateCamera event, Emitter<AttendanceState> emit) {
    if (state is AttendanceLoaded) {
      final currentState = state as AttendanceLoaded;
      emit(currentState.copyWith(isCameraActive: false, currentActionType: null));
    }
  }

  Future<void> _onFetchInitialData(
      FetchInitialData event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading(message: 'Fetching initial data...'));
    try {
      // Fetch employee profile data first
      final employeeProfile = await _profileRepository.getEmployeeProfile();
      final employeeId = employeeProfile['id'] as int; // Get employee ID

      // Fetch real attendance data using the repository
      final todayAttendance = await _attendanceRepository.getTodayAttendance(employeeId);
      final attendanceHistory = await _attendanceRepository.getAttendanceHistory(employeeId);

      emit(AttendanceLoaded(
        locationStatus: 'Mencari lokasi...',
        isLocationValid: false,
        faceRecognitionStatus: 'Menunggu verifikasi wajah...',
        isFaceRecognized: false,
        todayAttendance: todayAttendance,
        attendanceHistory: attendanceHistory,
        employeeProfile: employeeProfile, // Pass employee profile to state
        isCameraActive: false, // Ensure camera is off initially
        currentActionType: null, // Initialize current action type
      ));
    } catch (e) {
      emit(AttendanceError(message: 'Failed to fetch initial data: $e'));
    }
  }

  Future<void> _onUpdateDeviceLocation(
      UpdateDeviceLocation event, Emitter<AttendanceState> emit) async {
    if (state is! AttendanceLoaded) return; // Only proceed if state is loaded
    final currentState = state as AttendanceLoaded;

    if (event.position.isMocked) {
      emit(currentState.copyWith(
        isLocationValid: false,
        locationStatus: 'Lokasi palsu terdeteksi.',
        errorMessage: 'Deteksi lokasi palsu. Harap nonaktifkan aplikasi lokasi palsu.',
      ));
      return;
    }

    try {
      final userLatitude = event.position.latitude;
      final userLongitude = event.position.longitude;

      final List<dynamic> companyLocations = currentState.employeeProfile['company_attendance_locations'] ?? [];

      if (companyLocations.isEmpty) {
        emit(currentState.copyWith(
          isLocationValid: false,
          locationStatus: 'Tidak ada lokasi absensi yang terdaftar untuk perusahaan Anda.',
          errorMessage: 'Tidak ada lokasi absensi yang terdaftar.',
        ));
        return;
      }

      bool isWithinAnyLocation = false;
      String locationStatus = 'Anda berada di luar radius lokasi absensi.';

      for (var loc in companyLocations) {
        final companyAttendanceLatitude = loc['latitude'] as double;
        final companyAttendanceLongitude = loc['longitude'] as double;
        final companyAttendanceRadius = (loc['radius'] as int).toDouble();

        final distance = _haversineDistance(
          userLatitude,
          userLongitude,
          companyAttendanceLatitude,
          companyAttendanceLongitude,
        );

        if (distance <= companyAttendanceRadius) {
          isWithinAnyLocation = true;
          locationStatus = 'Anda berada di dalam radius lokasi: ${loc['name']}.';
          break; // Exit loop once a valid location is found
        }
      }

      if (isWithinAnyLocation) {
        emit(currentState.copyWith(
          isLocationValid: true,
          locationStatus: locationStatus,
          errorMessage: null,
        ));
      } else {
        emit(currentState.copyWith(
          isLocationValid: false,
          locationStatus: locationStatus,
          errorMessage: 'Lokasi tidak valid.',
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isLocationValid: false,
        locationStatus: 'Gagal mendapatkan lokasi perangkat.',
        errorMessage: 'Gagal mendapatkan lokasi perangkat. Pastikan GPS aktif dan izin diberikan.',
      ));
    }
  }

  Future<void> _onStartLocationUpdates(
      StartLocationUpdates event, Emitter<AttendanceState> emit) async {
    if (state is! AttendanceLoaded) {
      return;
    }

    await _positionStreamSubscription?.cancel();

    try {
      LocationPermission permission = await _geolocatorPlatform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocatorPlatform.requestPermission();
        if (permission == LocationPermission.denied) {
          emit((state as AttendanceLoaded).copyWith(
            isLocationValid: false,
            locationStatus: 'Izin lokasi ditolak.',
            errorMessage: 'Izin lokasi ditolak.',
          ));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit((state as AttendanceLoaded).copyWith(
          isLocationValid: false,
          locationStatus: 'Izin lokasi ditolak secara permanen.',
          errorMessage: 'Izin lokasi ditolak secara permanen. Harap aktifkan dari pengaturan aplikasi.',
        ));
        return;
      }

      _positionStreamSubscription = _geolocatorPlatform.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // Update every 100 meters
        ),
      ).listen(
        (Position position) {
          add(UpdateDeviceLocation(position: position));
        },
        onError: (error) {
          // Optionally handle stream errors, e.g., emit an error state
        },
        cancelOnError: false, // Keep listening even after an error
      );
    } catch (e) {
      emit((state as AttendanceLoaded).copyWith(
        isLocationValid: false,
        locationStatus: 'Gagal memulai pembaruan lokasi.',
        errorMessage: 'Gagal memulai pembaruan lokasi: $e',
      ));
    }
  }

  Future<void> _onStopLocationUpdates(
      StopLocationUpdates event, Emitter<AttendanceState> emit) async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }

  Future<void> _onTakePhotoAndVerifyFace(
      TakePhotoAndVerifyFace event, Emitter<AttendanceState> emit) async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    if (!currentState.isLocationValid) {
      emit(currentState.copyWith(errorMessage: 'Lokasi tidak valid. Pastikan Anda berada di dalam area yang diizinkan.'));
      return;
    }

    emit(currentState.copyWith(isCameraActive: false, faceRecognitionStatus: 'Mengompres gambar dan memverifikasi wajah...'));

    try {
      // 1. Compress the image
      Uint8List? compressedImageBytes;
      try {
        compressedImageBytes = await FlutterImageCompress.compressWithFile(
          event.imageFile.path,
          minWidth: 480, // Further reduce width to decrease file size
          quality: 60,     // Lower quality for a smaller file, still viable for recognition
        );
      } catch (e) {
        // If compression fails, fall back to the original image
        compressedImageBytes = await File(event.imageFile.path).readAsBytes();
      }

      if (compressedImageBytes == null) {
        throw Exception("Gagal memproses gambar.");
      }

      // 2. Convert image to Base64
      final imageData = base64Encode(compressedImageBytes);

      // 3. Get current location
      final position = await _geolocatorPlatform.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final employeeId = currentState.employeeProfile['id'] as int;

      // 4. Call the appropriate repository method
      switch (event.actionType) {
        case 'check_in':
        case 'check_out':
          await _attendanceRepository.handleAttendance(
            employeeId: employeeId,
            latitude: position.latitude,
            longitude: position.longitude,
            imageData: imageData,
          );
          break;
        case 'overtime_in':
          await _attendanceRepository.handleOvertimeCheckIn(
            employeeId: employeeId,
            latitude: position.latitude,
            longitude: position.longitude,
            imageData: imageData,
          );
          break;
        case 'overtime_out':
          await _attendanceRepository.handleOvertimeCheckOut(
            employeeId: employeeId,
            latitude: position.latitude,
            longitude: position.longitude,
            imageData: imageData,
          );
          break;
        default:
          throw Exception('Invalid attendance action type');
      }

      // 5. On success, refetch only the necessary data to update the UI
      final updatedTodayAttendance = await _attendanceRepository.getTodayAttendance(employeeId);
      final updatedAttendanceHistory = await _attendanceRepository.getAttendanceHistory(employeeId);

      emit(currentState.copyWith(
        faceRecognitionStatus: 'Absensi berhasil diverifikasi dan direkam!',
        todayAttendance: updatedTodayAttendance,
        attendanceHistory: updatedAttendanceHistory,
        isCameraActive: false,
        currentActionType: null,
        errorMessage: null, // Clear any previous error messages
      ));

    } catch (e) {
      // On failure, show an error message
      emit(currentState.copyWith(
        isFaceRecognized: false,
        faceRecognitionStatus: 'Gagal melakukan absensi.',
        errorMessage: e.toString(),
        isCameraActive: false,
      ));
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth's radius in meters
    final phi1 = lat1 * (pi / 180);
    final phi2 = lat2 * (pi / 180);
    final deltaPhi = (lat2 - lat1) * (pi / 180);
    final deltaLambda = (lon2 - lon1) * (pi / 180);

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
              cos(phi1) * cos(phi2) *
              sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final d = R * c; // in meters
    return d;
  }
}
