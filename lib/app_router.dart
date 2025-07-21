
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/bloc/auth/auth_bloc.dart';

import 'package:flutter_face_auth_app/pages/announcement_page.dart';
import 'package:flutter_face_auth_app/pages/attendance_page.dart';
import 'package:flutter_face_auth_app/pages/camera_screen.dart';
import 'package:flutter_face_auth_app/pages/employee_leave_request_page.dart';
import 'package:flutter_face_auth_app/pages/employee_profile_page.dart';
import 'package:flutter_face_auth_app/pages/employee_tabs_page.dart';
import 'package:flutter_face_auth_app/pages/force_face_upload_page.dart';
import 'package:flutter_face_auth_app/pages/login_page.dart';
import 'package:flutter_face_auth_app/pages/splash_screen.dart';
import 'package:flutter_face_auth_app/utils/go_router_refresh_stream.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter appRouter(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final onSplash = state.matchedLocation == '/splash';

      if (onSplash) {
        return null;
      }

      if (authState is AuthInitial || authState is AuthLoading) {
        return '/splash';
      }

      if (authState is Unauthenticated) {
        return '/login';
      }

      if (authState is AuthNeedsFaceRegistration) {
        return '/force-face-upload';
      }

      if (authState is Authenticated) {
        if (state.matchedLocation == '/login' || state.matchedLocation == '/splash' || state.matchedLocation == '/force-face-upload') {
          return '/employee';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/force-face-upload',
        builder: (context, state) => const ForceFaceUploadPage(),
      ),
      GoRoute(
        path: '/smile-test',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeTabsPage(),
        routes: [
          GoRoute(
            path: 'announcements',
            builder: (context, state) => const AnnouncementPage(),
          ),
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const AttendancePage(),
          ),
          GoRoute(
            path: 'leave-requests',
            builder: (context, state) => const EmployeeLeaveRequestPage(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const EmployeeProfilePage(),
          ),
        ],
      ),
    ],
  );
}


