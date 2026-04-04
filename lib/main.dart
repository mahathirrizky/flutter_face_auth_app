import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import 'package:flutter_face_auth_app/locator.dart';
import 'package:flutter_face_auth_app/app_router.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/cubit/cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  setupLocator();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AnnouncementBloc>(
          create: (context) => getIt<AnnouncementBloc>(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<EmployeeProfileBloc>(
          create: (context) => getIt<EmployeeProfileBloc>(),
        ),
        BlocProvider<FaceUploadBloc>(
          create: (context) => getIt<FaceUploadBloc>(),
        ),
        BlocProvider<AttendanceBloc>(
          create: (context) => getIt<AttendanceBloc>(),
        ),
        BlocProvider<LeaveRequestBloc>(
          create: (context) => getIt<LeaveRequestBloc>(),
        ),
        BlocProvider<EmployeeHomeCubit>(
          create: (context) => getIt<EmployeeHomeCubit>(),
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
    );
  }
}
