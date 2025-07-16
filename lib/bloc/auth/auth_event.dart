part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class LogoutRequested extends AuthEvent {}

class FaceRegistrationCompleted extends AuthEvent {}
