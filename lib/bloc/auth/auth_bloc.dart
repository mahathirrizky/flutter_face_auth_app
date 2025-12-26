import 'package:bloc/bloc.dart';
import 'package:flutter_face_auth_app/repositories/profile_repository.dart';
import 'package:meta/meta.dart';
import 'package:flutter_face_auth_app/repositories/auth_repository.dart';
import 'package:flutter_face_auth_app/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  WebSocketService? _webSocketService;
  final Function(dynamic) _onWebSocketMessage;

  AuthBloc({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required Function(dynamic) onWebSocketMessage,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _onWebSocketMessage = onWebSocketMessage,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<FaceRegistrationCompleted>(_onFaceRegistrationCompleted);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('DEBUG: AuthBloc - AuthCheckRequested received.');
    final hasToken = await _authRepository.hasToken();
    print('DEBUG: AuthBloc - hasToken: $hasToken');

    if (hasToken) {
      try {
        final profile = await _profileRepository.getEmployeeProfile();
        final isFaceRegistered = profile['face_image_registered'] == true;
        print('DEBUG: AuthBloc - Profile fetched. isFaceRegistered: $isFaceRegistered');

        if (isFaceRegistered) {
          emit(Authenticated());
          print('DEBUG: AuthBloc - Emitting Authenticated state.');
          _reconnectWebSocket();
        } else {
          emit(AuthNeedsFaceRegistration());
          print('DEBUG: AuthBloc - Emitting AuthNeedsFaceRegistration state.');
        }
      } catch (e) {
        print('DEBUG: AuthBloc - Error checking profile: $e');
        await _authRepository.logout();
        emit(Unauthenticated());
        print('DEBUG: AuthBloc - Emitting Unauthenticated state due to profile error.');
        _webSocketService?.disconnect();
      }
    } else {
      emit(Unauthenticated());
      print('DEBUG: AuthBloc - Emitting Unauthenticated state (no token).');
      _webSocketService?.disconnect();
    }
  }

  Future<void> _onFaceRegistrationCompleted(
    FaceRegistrationCompleted event,
    Emitter<AuthState> emit,
  ) async {
    print('DEBUG: AuthBloc - FaceRegistrationCompleted received.');
    emit(Authenticated());
    print('DEBUG: AuthBloc - Emitting Authenticated state after face registration.');
    _reconnectWebSocket();
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('DEBUG: AuthBloc - AuthLoginRequested received.');
    emit(AuthLoading());
    try {
      await _authRepository.loginEmployee(event.email, event.password);
      final profile = await _profileRepository.getEmployeeProfile();
      final isFaceRegistered = profile['face_image_registered'] == true;
      print('DEBUG: AuthBloc - Login successful. isFaceRegistered: $isFaceRegistered');

      if (isFaceRegistered) {
        emit(Authenticated());
        print('DEBUG: AuthBloc - Emitting Authenticated state after login.');
        _reconnectWebSocket();
      } else {
        emit(AuthNeedsFaceRegistration());
        print('DEBUG: AuthBloc - Emitting AuthNeedsFaceRegistration state after login.');
      }
    } catch (e) {
      print('DEBUG: AuthBloc - Login failed: $e');
      // Jika error adalah karena sesi kedaluwarsa, logout dan arahkan ke login
      if (e.toString().contains('Session expired')) {
        await _authRepository.logout();
        emit(Unauthenticated());
      } else {
        emit(AuthFailure(message: e.toString()));
      }
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('DEBUG: AuthBloc - LogoutRequested received.');
    emit(AuthLoading());
    try {
      _webSocketService?.disconnect();
      await _authRepository.logout();
      emit(AuthLogoutSuccess());
      print('DEBUG: AuthBloc - Emitting AuthLogoutSuccess state.');
    } catch (e) {
      print('DEBUG: AuthBloc - Logout failed: $e');
      emit(AuthLogoutFailure(message: e.toString()));
    }
  }

  Future<void> _reconnectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _initAndConnectWebSocket(token);
    }
  }

  void _initAndConnectWebSocket(String token) {
    // Disconnect any existing WebSocket service before creating a new one
    _webSocketService?.disconnect();

    const String wsBaseUrl = '457c68305f78.ngrok-free.app';
    const String wsNotificationPath = '/ws/employee-notifications';
    final String fullWebSocketUrl = 'wss://$wsBaseUrl$wsNotificationPath?token=$token';
    print('DEBUG: Full WebSocket URL: $fullWebSocketUrl');

    _webSocketService = WebSocketService(
      fullWebSocketUrl: fullWebSocketUrl,
      onMessageReceived: (message) {
        // This is where the message is processed and passed to the callback
        _onWebSocketMessage(message);
      },
      onError: (error) {
        print('AuthBloc WebSocket error: $error');
      },
      onDisconnected: () {
        print('AuthBloc WebSocket disconnected.');
        _webSocketService = null;
      },
    );
    _webSocketService?.connect();
  }

  @override
  Future<void> close() {
    _webSocketService?.disconnect();
    return super.close();
  }
}

