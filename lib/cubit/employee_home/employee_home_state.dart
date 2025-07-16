part of 'employee_home_cubit.dart';

@immutable
sealed class EmployeeHomeState {}

final class EmployeeHomeInitial extends EmployeeHomeState {}

final class EmployeeHomeLoading extends EmployeeHomeState {}

final class EmployeeHomeLoaded extends EmployeeHomeState {
  final String employeeName;
  final String employeePosition;
  final String todayAttendanceStatus;
  final int pendingLeaveRequestsCount;
  final List<Map<String, dynamic>> recentAttendances;

  EmployeeHomeLoaded({
    required this.employeeName,
    required this.employeePosition,
    required this.todayAttendanceStatus,
    required this.pendingLeaveRequestsCount,
    required this.recentAttendances,
  });
}

final class EmployeeHomeError extends EmployeeHomeState {
  final String message;

  EmployeeHomeError({required this.message});
}