
import 'dart:convert';
import 'package:flutter_face_auth_app/repositories/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
import 'package:flutter_face_auth_app/locator.dart';

class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? getIt<ApiClient>();

  Future<List<Map<String, dynamic>>> getAttendanceHistory(int employeeId) async {
    final response = await _apiClient.get(
      Uri.parse('${ApiClient.baseUrl}/employees/$employeeId/attendances'),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final List<dynamic> data = responseBody['data'];
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to load attendance history');
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance(int employeeId) async {
    final history = await getAttendanceHistory(employeeId);
    final today = DateTime.now();
    for (var record in history) {
      if (record['check_in_time'] == null || record['check_in_time'] == "") continue;
      final checkInTime = DateTime.parse(record['check_in_time']).toLocal();
      if (checkInTime.year == today.year &&
          checkInTime.month == today.month &&
          checkInTime.day == today.day) {
        return record;
      }
    }
    return {
      'check_in_time': '',
      'noon_check_time': '',
      'check_out_time': '',
      'status': 'Belum Absen',
      'noon_status': 'Belum Absen',
    };
  }

  Future<Map<String, dynamic>> handleAttendance({
    required int employeeId,
    required double latitude,
    required double longitude,
    required String imageData,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiClient.baseUrl}/attendance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'image_data': imageData,
      }),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to handle attendance');
    }
  }

  Future<Map<String, dynamic>> handleOvertimeCheckIn({
    required int employeeId,
    required double latitude,
    required double longitude,
    required String imageData,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiClient.baseUrl}/overtime/check-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'image_data': imageData,
      }),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to handle overtime check-in');
    }
  }

  Future<Map<String, dynamic>> handleOvertimeCheckOut({
    required int employeeId,
    required double latitude,
    required double longitude,
    required String imageData,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiClient.baseUrl}/overtime/check-out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_id': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'image_data': imageData,
      }),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      throw CustomException(responseBody['message'] ?? 'Failed to handle overtime check-out');
    }
  }
}
