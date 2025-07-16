part of 'employee_profile_bloc.dart';

@immutable
sealed class EmployeeProfileState {}

final class EmployeeProfileInitial extends EmployeeProfileState {}

final class EmployeeProfileLoading extends EmployeeProfileState {
  final String message;
  EmployeeProfileLoading({this.message = 'Loading profile...'});
}

final class EmployeeProfileLoaded extends EmployeeProfileState {
  final String name;
  final String email;
  final String position;
  final Map<String, dynamic>? shiftInfo;
  final String? successMessage;
  final String? errorMessage;

  EmployeeProfileLoaded({
    required this.name,
    required this.email,
    required this.position,
    this.shiftInfo,
    this.successMessage,
    this.errorMessage,
  });

  EmployeeProfileLoaded copyWith({
    String? name,
    String? email,
    String? position,
    Map<String, dynamic>? shiftInfo,
    String? successMessage,
    String? errorMessage,
  }) {
    return EmployeeProfileLoaded(
      name: name ?? this.name,
      email: email ?? this.email,
      position: position ?? this.position,
      shiftInfo: shiftInfo ?? this.shiftInfo,
      successMessage: successMessage, // Allow setting to null
      errorMessage: errorMessage,     // Allow setting to null
    );
  }
}

final class EmployeeProfileError extends EmployeeProfileState {
  final String message;
  EmployeeProfileError({required this.message});
}