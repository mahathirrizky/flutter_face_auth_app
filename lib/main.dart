import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/repositories/announcement_repository.dart';
import 'package:flutter_face_auth_app/repositories/attendance_repository.dart';
import 'package:flutter_face_auth_app/repositories/dashboard_repository.dart';
import 'package:flutter_face_auth_app/repositories/leave_request_repository.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_face_auth_app/app_router.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/repositories/auth_repository.dart';
import 'package:flutter_face_auth_app/repositories/profile_repository.dart';
import 'package:flutter_face_auth_app/cubit/cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories once
    final authRepository = AuthRepository();
    final profileRepository = ProfileRepository();
    final announcementRepository = AnnouncementRepository();
    final attendanceRepository = AttendanceRepository();
    final leaveRequestRepository = LeaveRequestRepository();
    final dashboardRepository = DashboardRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: announcementRepository),
        RepositoryProvider.value(value: attendanceRepository),
        RepositoryProvider.value(value: leaveRequestRepository),
        RepositoryProvider.value(value: dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AnnouncementBloc>(
            create: (context) => AnnouncementBloc(announcementRepository: announcementRepository),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: authRepository,
              profileRepository: profileRepository,
              onWebSocketMessage: (message) {
                if (message['type'] == 'broadcast_message') {
                  final announcementPayload = message['payload'];
                  final announcement = Announcement.fromJson(announcementPayload);
                  context.read<AnnouncementBloc>().add(ReceiveNewAnnouncement(announcement: announcement));
                }
              },
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<EmployeeProfileBloc>(
            create: (context) => EmployeeProfileBloc(profileRepository: profileRepository),
          ),
          BlocProvider<FaceUploadBloc>(
            create: (context) => FaceUploadBloc(profileRepository: profileRepository),
          ),
          BlocProvider<AttendanceBloc>(
            create: (context) => AttendanceBloc(
              profileRepository: profileRepository,
              attendanceRepository: attendanceRepository,
            ),
          ),
          BlocProvider<LeaveRequestBloc>(
            create: (context) => LeaveRequestBloc(leaveRequestRepository: leaveRequestRepository),
          ),
          BlocProvider<EmployeeHomeCubit>(
            create: (context) => EmployeeHomeCubit(dashboardRepository: dashboardRepository),
          ),
        ],
        child: ToastificationWrapper(
          child: Builder(
            builder: (context) {
              return MaterialApp.router(
                routerConfig: appRouter(context),
                title: 'Flutter Face Auth',
                debugShowCheckedModeBanner: false,
                theme: appTheme(),
              );
            }
          ),
        ),
      ),
    );
  }
}
