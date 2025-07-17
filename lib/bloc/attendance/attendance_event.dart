part of 'attendance_bloc.dart';

@immutable
sealed class AttendanceEvent {}

class FetchInitialData extends AttendanceEvent {}

class ActivateCamera extends AttendanceEvent {
  final String actionType; // e.g., 'check_in', 'check_out'
  ActivateCamera({required this.actionType});
}

class DeactivateCamera extends AttendanceEvent {}

class TakePhotoAndVerifyFace extends AttendanceEvent {
  final XFile imageFile;
  final String actionType; // e.g., 'check_in', 'check_out'

  TakePhotoAndVerifyFace({required this.imageFile, required this.actionType});
}

class PerformAttendanceAction extends AttendanceEvent {
  final String actionType; // e.g., 'check_in', 'check_out', 'overtime_in', 'overtime_out'

  PerformAttendanceAction({required this.actionType});
}

class UpdateDeviceLocation extends AttendanceEvent {
  final Position position;

  UpdateDeviceLocation({required this.position});

 
  List<Object> get props => [position];
}

class StartLocationUpdates extends AttendanceEvent {}

class StopLocationUpdates extends AttendanceEvent {}
