part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {}

class Unauthenticated extends AuthState {}

// This state will be emitted when the user is authenticated but needs to register their face.
class AuthNeedsFaceRegistration extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure({required this.message});
}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}

class AuthLogoutSuccess extends AuthState {}

class AuthLogoutFailure extends AuthState {
  final String message;
  AuthLogoutFailure({required this.message});
}
