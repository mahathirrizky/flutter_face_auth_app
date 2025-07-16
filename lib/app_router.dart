import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/pages/login_page.dart';
import 'package:flutter_face_auth_app/pages/camera_screen.dart';
import 'package:flutter_face_auth_app/pages/employee_tabs_page.dart';
import 'package:flutter_face_auth_app/pages/employee_home_page.dart';
import 'package:flutter_face_auth_app/pages/attendance_page.dart';
import 'package:flutter_face_auth_app/pages/employee_leave_request_page.dart';
import 'package:flutter_face_auth_app/pages/announcement_page.dart';
import 'package:flutter_face_auth_app/pages/employee_profile_page.dart';
import 'package:flutter_face_auth_app/pages/splash_screen.dart';
import 'package:flutter_face_auth_app/pages/force_face_upload_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
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
          path: 'home',
          builder: (context, state) => const EmployeeHomePage(),
        ),
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


