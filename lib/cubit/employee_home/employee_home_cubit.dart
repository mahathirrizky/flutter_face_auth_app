import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_face_auth_app/repositories/dashboard_repository.dart'; // Import DashboardRepository

part 'employee_home_state.dart';

class EmployeeHomeCubit extends Cubit<EmployeeHomeState> {
  final DashboardRepository _dashboardRepository;

  EmployeeHomeCubit({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(EmployeeHomeInitial());

  Future<void> fetchDashboardSummary() async {
    emit(EmployeeHomeLoading());
    try {
      final dashboardData = await _dashboardRepository.getEmployeeDashboardSummary();
      print('DEBUG: EmployeeHomeCubit received dashboardData: $dashboardData'); // <--- Added this line

      emit(EmployeeHomeLoaded(
        employeeName: dashboardData['employee_name'] ?? 'Nama tidak tersedia',
        employeePosition: dashboardData['employee_position'] ?? 'Posisi tidak tersedia',
        todayAttendanceStatus: dashboardData['today_attendance_status'] ?? 'Status tidak tersedia',
        pendingLeaveRequestsCount: dashboardData['pending_leave_requests_count'] ?? 0,
        recentAttendances: List<Map<String, dynamic>>.from(dashboardData['recent_attendances'] ?? []),
      ));
    } catch (e) {
      emit(EmployeeHomeError(message: e.toString()));
    }
  }
}