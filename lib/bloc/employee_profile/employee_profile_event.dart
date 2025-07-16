part of 'employee_profile_bloc.dart';

@immutable
sealed class EmployeeProfileEvent {}

class LoadEmployeeProfile extends EmployeeProfileEvent {}

class UpdateEmployeeProfile extends EmployeeProfileEvent {
  final String name;
  final String email;
  final String position;

  UpdateEmployeeProfile({
    required this.name,
    required this.email,
    required this.position,
  });
}

class ChangeEmployeePassword extends EmployeeProfileEvent {
  final String newPassword;
  final String confirmNewPassword;

  ChangeEmployeePassword({
    required this.newPassword,
    required this.confirmNewPassword,
  });
}