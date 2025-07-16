import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_auth_app/theme/app_theme.dart';
import 'package:flutter_face_auth_app/cubit/cubit.dart';

class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger data fetch when the page is built
    context.read<EmployeeHomeCubit>().fetchDashboardSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: AppColors.bgMuted,
        foregroundColor: AppColors.textBase,
        toolbarHeight: 45.0,
        elevation: 0.0,
        shadowColor: Colors.transparent,
      ),
      body: BlocBuilder<EmployeeHomeCubit, EmployeeHomeState>(
        builder: (context, state) {
          if (state is EmployeeHomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is EmployeeHomeLoaded) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Card
                    Card(
                      color: AppColors.bgMuted,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${state.employeeName}!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBase,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.employeePosition,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Todays Attendance: ${state.todayAttendanceStatus}',
                              style: TextStyle(color: AppColors.textBase),
                            ),
                            Text(
                              'Pending Leave Requests: ${state.pendingLeaveRequestsCount}',
                              style: TextStyle(color: AppColors.textBase),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recent Attendances Card
                    Card(
                      color: AppColors.bgMuted,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Attendances',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textBase,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (state.recentAttendances.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.recentAttendances.length,
                                itemBuilder: (context, index) {
                                  final attendance = state.recentAttendances[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDate(attendance['check_in_time']),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textBase,
                                          ),
                                        ),
                                        Text(
                                          'Check-in: ${_formatTime(attendance['check_in_time'])}',
                                          style: TextStyle(color: AppColors.textMuted),
                                        ),
                                        if (attendance['check_out_time'] != null && attendance['check_out_time'].isNotEmpty)
                                          Text(
                                            'Check-out: ${_formatTime(attendance['check_out_time'])}',
                                            style: TextStyle(color: AppColors.textMuted),
                                          ),
                                        Text(
                                          'Status: ${attendance['status']}',
                                          style: TextStyle(color: AppColors.textMuted),
                                        ),
                                        if (index < state.recentAttendances.length - 1)
                                          const Divider(color: AppColors.textMuted), // Separator
                                      ],
                                    ),
                                  );
                                },
                              )
                            else
                              Text(
                                'No recent attendance records.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is EmployeeHomeError) {
            return Center(child: Text('Error: ${state.message}', style: TextStyle(color: Colors.red)));
          } else {
            return const Center(child: Text('Initial State'));
          }
        },
      ),
    );
  }

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return '';
    final dateTime = DateTime.parse(isoString).toLocal();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    final dateTime = DateTime.parse(isoString).toLocal();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
