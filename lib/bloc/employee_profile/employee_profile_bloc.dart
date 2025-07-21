import 'package:bloc/bloc.dart';
import 'package:flutter_face_auth_app/repositories/profile_repository.dart';
import 'package:meta/meta.dart';

part 'employee_profile_event.dart';
part 'employee_profile_state.dart';

class EmployeeProfileBloc extends Bloc<EmployeeProfileEvent, EmployeeProfileState> {
  final ProfileRepository _profileRepository;

  EmployeeProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(EmployeeProfileInitial()) {
    on<LoadEmployeeProfile>(_onLoadEmployeeProfile);
    on<UpdateEmployeeProfile>(_onUpdateEmployeeProfile);
    on<ChangeEmployeePassword>(_onChangeEmployeePassword);
  }

  Future<void> _onLoadEmployeeProfile(
      LoadEmployeeProfile event, Emitter<EmployeeProfileState> emit) async {
    emit(EmployeeProfileLoading(message: 'Memuat data profil...'));
    try {
      final profileData = await _profileRepository.getEmployeeProfile();

      emit(EmployeeProfileLoaded(
        name: profileData['name'] ?? 'Nama tidak tersedia',
        email: profileData['email'] ?? 'Email tidak tersedia',
        position: profileData['position'] ?? 'Posisi tidak tersedia',
        shiftInfo: profileData['shift'] as Map<String, dynamic>?,
      ));
    } catch (e) {
      print('DEBUG: Error loading employee profile: $e'); // <--- Added this line
      emit(EmployeeProfileError(message: 'Gagal memuat profil: $e'));
    }
  }

  Future<void> _onUpdateEmployeeProfile(
      UpdateEmployeeProfile event, Emitter<EmployeeProfileState> emit) async {
    if (state is! EmployeeProfileLoaded) return;
    final currentState = state as EmployeeProfileLoaded;

    emit(currentState.copyWith(successMessage: null, errorMessage: null)); // Clear messages

    try {
      await _profileRepository.updateEmployeeProfile(
        name: event.name,
        email: event.email,
        position: event.position,
      );

      // After successful update, re-fetch the profile to ensure data consistency
      final updatedProfile = await _profileRepository.getEmployeeProfile();

      emit(currentState.copyWith(
        name: updatedProfile['name'] ?? event.name,
        email: updatedProfile['email'] ?? event.email,
        position: updatedProfile['position'] ?? event.position,
        successMessage: 'Profil berhasil diperbarui!',
        errorMessage: null,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Gagal memperbarui profil: $e',
        successMessage: null,
      ));
    }
  }

  Future<void> _onChangeEmployeePassword(
      ChangeEmployeePassword event, Emitter<EmployeeProfileState> emit) async {
    if (state is! EmployeeProfileLoaded) return;
    final currentState = state as EmployeeProfileLoaded;

    emit(currentState.copyWith(successMessage: null, errorMessage: null)); // Clear messages

    if (event.newPassword.isEmpty || event.confirmNewPassword.isEmpty) {
      emit(currentState.copyWith(errorMessage: 'Harap isi semua kolom kata sandi.'));
      return;
    }
    if (event.newPassword != event.confirmNewPassword) {
      emit(currentState.copyWith(errorMessage: 'Kata sandi baru dan konfirmasi tidak cocok.'));
      return;
    }
    if (event.newPassword.length < 6) {
      emit(currentState.copyWith(errorMessage: 'Kata sandi minimal 6 karakter.'));
      return;
    }

    try {
      await _profileRepository.changeEmployeePassword(
        newPassword: event.newPassword,
        confirmNewPassword: event.confirmNewPassword,
      );

      emit(currentState.copyWith(
        successMessage: 'Kata sandi berhasil diubah!',
        errorMessage: null, // Clear any previous error
      ));
    } catch (e) {
      emit(currentState.copyWith(
        errorMessage: 'Gagal mengubah kata sandi: $e',
        successMessage: null,
      ));
    }
  }
}