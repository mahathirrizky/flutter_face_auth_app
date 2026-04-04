import 'package:get_it/get_it.dart';

import 'package:flutter_face_auth_app/repositories/announcement_repository.dart';
import 'package:flutter_face_auth_app/repositories/attendance_repository.dart';
import 'package:flutter_face_auth_app/repositories/auth_repository.dart';
import 'package:flutter_face_auth_app/repositories/dashboard_repository.dart';
import 'package:flutter_face_auth_app/repositories/leave_request_repository.dart';
import 'package:flutter_face_auth_app/repositories/profile_repository.dart';

import 'package:flutter_face_auth_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_face_auth_app/bloc/announcement/announcement_bloc.dart';
import 'package:flutter_face_auth_app/bloc/attendance/attendance_bloc.dart';
import 'package:flutter_face_auth_app/bloc/employee_profile/employee_profile_bloc.dart';
import 'package:flutter_face_auth_app/bloc/face_upload/face_upload_bloc.dart';
import 'package:flutter_face_auth_app/bloc/leave_request/leave_request_bloc.dart';
import 'package:flutter_face_auth_app/cubit/employee_home/employee_home_cubit.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // -------------------------------------------------------------
  // Repositories (Lazy Singletons - Diinisialisasi hanya jika dipanggil)
  // -------------------------------------------------------------
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepository());
  getIt.registerLazySingleton<AnnouncementRepository>(() => AnnouncementRepository());
  getIt.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository());
  getIt.registerLazySingleton<LeaveRequestRepository>(() => LeaveRequestRepository());
  getIt.registerLazySingleton<DashboardRepository>(() => DashboardRepository());

  // -------------------------------------------------------------
  // Blocs / Cubits (Factories - Membuat instance baru tiap diminta)
  // Khusus AuthBloc bisa jadi LazySingleton karena sifatnya global
  // -------------------------------------------------------------
  
  // AnnouncementBloc is a LazySingleton because it handles global announcements from WebSocket
  getIt.registerLazySingleton<AnnouncementBloc>(
      () => AnnouncementBloc(announcementRepository: getIt<AnnouncementRepository>()));

  // AuthBloc harus Singleton karena state auth global
  getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(
        authRepository: getIt<AuthRepository>(),
        profileRepository: getIt<ProfileRepository>(),
        onWebSocketMessage: (message) {
          if (message['type'] == 'broadcast_message') {
            try {
              final announcementPayload = message['payload'];
              final announcement = Announcement.fromJson(announcementPayload);
              getIt<AnnouncementBloc>().add(ReceiveNewAnnouncement(announcement: announcement));
            } catch (e) {
              // ignore error formatting
            }
          }
        },
      ));

  getIt.registerFactory<EmployeeProfileBloc>(
      () => EmployeeProfileBloc(profileRepository: getIt<ProfileRepository>()));

  getIt.registerFactory<FaceUploadBloc>(
      () => FaceUploadBloc(profileRepository: getIt<ProfileRepository>()));

  getIt.registerFactory<AttendanceBloc>(() => AttendanceBloc(
        profileRepository: getIt<ProfileRepository>(),
        attendanceRepository: getIt<AttendanceRepository>(),
      ));

  getIt.registerFactory<LeaveRequestBloc>(
      () => LeaveRequestBloc(leaveRequestRepository: getIt<LeaveRequestRepository>()));

  getIt.registerFactory<EmployeeHomeCubit>(
      () => EmployeeHomeCubit(dashboardRepository: getIt<DashboardRepository>()));
}
