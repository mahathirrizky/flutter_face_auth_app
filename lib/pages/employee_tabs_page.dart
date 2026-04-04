
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 450) {
          return Row(
            children: <Widget>[
              NavigationRail(
                minWidth: 80,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelType: NavigationRailLabelType.all,
                indicatorColor: AppColors.secondary.withOpacity(0.2),
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home, color: AppColors.secondary),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign, color: AppColors.secondary),
                    label: Text('Announce'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.check_circle_outline),
                    selectedIcon: Icon(Icons.check_circle, color: AppColors.secondary),
                    label: Text('Attendance'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_today, color: AppColors.secondary),
                    label: Text('Leave'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: AppColors.secondary),
                    label: Text('Profile'),
                  ),
                ],
                backgroundColor: AppColors.bgMuted,
                groupAlignment: 0.0,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // This is the main content.
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          );
        } else {
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: AppColors.bgMuted,
              indicatorColor: AppColors.secondary.withOpacity(0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.secondary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  selectedIcon: Icon(Icons.campaign, color: AppColors.secondary),
                  label: 'Announce',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle, color: AppColors.secondary),
                  label: 'Attendance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today, color: AppColors.secondary),
                  label: 'Leave',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppColors.secondary),
                  label: 'Profile',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
