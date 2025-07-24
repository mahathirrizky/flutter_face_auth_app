part of 'attendance_bloc.dart';

@immutable
sealed class AttendanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class AttendanceInitial extends AttendanceState {}

final class AttendanceLoading extends AttendanceState {
  final String message;
  AttendanceLoading({this.message = 'Loading data...'});

  @override
  List<Object?> get props => [message];
}

final class AttendanceLoaded extends AttendanceState {
  final String locationStatus;
  final bool isLocationValid;
  final String faceRecognitionStatus;
  final bool isFaceRecognized;
  final Map<String, dynamic> todayAttendance;
  final List<Map<String, dynamic>> attendanceHistory;
  final Map<String, dynamic> employeeProfile;
  final bool isCameraActive;
  final String? currentActionType; // New property to store the action type
  final String? errorMessage;

  AttendanceLoaded({
    required this.locationStatus,
    required this.isLocationValid,
    required this.faceRecognitionStatus,
    required this.isFaceRecognized,
    required this.todayAttendance,
    required this.attendanceHistory,
    required this.employeeProfile,
    this.isCameraActive = false,
    this.currentActionType, // Initialize it
    this.errorMessage,
  });

  AttendanceLoaded copyWith({
    String? locationStatus,
    bool? isLocationValid,
    String? faceRecognitionStatus,
    bool? isFaceRecognized,
    Map<String, dynamic>? todayAttendance,
    List<Map<String, dynamic>>? attendanceHistory,
    Map<String, dynamic>? employeeProfile,
    bool? isCameraActive,
    String? currentActionType,
    String? errorMessage,
  }) {
    return AttendanceLoaded(
      locationStatus: locationStatus ?? this.locationStatus,
      isLocationValid: isLocationValid ?? this.isLocationValid,
      faceRecognitionStatus: faceRecognitionStatus ?? this.faceRecognitionStatus,
      isFaceRecognized: isFaceRecognized ?? this.isFaceRecognized,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
      employeeProfile: employeeProfile ?? this.employeeProfile,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      currentActionType: currentActionType ?? this.currentActionType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        locationStatus,
        isLocationValid,
        faceRecognitionStatus,
        isFaceRecognized,
        todayAttendance,
        attendanceHistory,
        employeeProfile,
        isCameraActive,
        currentActionType,
        errorMessage,
      ];
}

final class AttendanceError extends AttendanceState {
  final String message;
  AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}


