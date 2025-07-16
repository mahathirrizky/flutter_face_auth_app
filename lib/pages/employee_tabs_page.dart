
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart';
import 'package:flutter_face_auth_app/pages/announcement_page.dart';
import 'package:flutter_face_auth_app/pages/attendance_page.dart';
import 'package:flutter_face_auth_app/pages/employee_home_page.dart';
import 'package:flutter_face_auth_app/pages/employee_leave_request_page.dart';
import 'package:flutter_face_auth_app/pages/employee_profile_page.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';

class EmployeeTabsPage extends StatefulWidget {
  const EmployeeTabsPage({super.key});

  @override
  State<EmployeeTabsPage> createState() => _EmployeeTabsPageState();
}

class _EmployeeTabsPageState extends State<EmployeeTabsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EmployeeHomePage(),
    const AnnouncementPage(),
    const AttendancePage(),
    const EmployeeLeaveRequestPage(),
    const EmployeeProfilePage(),
  ];

  void _onItemTapped(int index) {
    final attendanceBloc = context.read<AttendanceBloc>();

    if (_selectedIndex == 2 && index != 2) {
      attendanceBloc.add(StopLocationUpdates());
      attendanceBloc.add(DeactivateCamera());
    } else if (_selectedIndex != 2 && index == 2) {
      attendanceBloc.add(StartLocationUpdates());
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Announce',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.bgMuted,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
