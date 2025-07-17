import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
// Model untuk LeaveRequest, sesuai dengan struktur di backend Go
class LeaveRequest {
  final int id;
  final int employeeId;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final int? reviewedBy;
  final DateTime? reviewedAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['ID'],
      employeeId: json['employee_id'],
      type: json['type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      reason: json['reason'],
      status: json['status'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
    );
  }
}

class LeaveRequestRepository {
  final String _baseUrl = 'https://api.4commander.my.id/api';

  LeaveRequestRepository();

  Future<LeaveRequest> applyLeave({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/leave-requests'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': type,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        final body = json.decode(response.body);
        return LeaveRequest.fromJson(body['data']);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to submit leave request.';
        throw Exception(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<List<LeaveRequest>> getMyLeaveRequests({String? startDate, String? endDate}) async {
    final client = ApiClient(http.Client());
    try {
      String url = '${ApiClient.baseUrl}/my-leave-requests';
      if (startDate != null && endDate != null) {
        url += '?start_date=$startDate&end_date=$endDate';
      } else if (startDate != null) {
        url += '?start_date=$startDate';
      } else if (endDate != null) {
        url += '?end_date=$endDate';
      }

      final response = await client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => LeaveRequest.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to fetch leave requests.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }
}
