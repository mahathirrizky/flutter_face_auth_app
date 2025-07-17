import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
class DashboardRepository {
  final String _baseUrl = 'https://api.4commander.my.id/api'; // Sesuaikan dengan URL base API Anda

  DashboardRepository();

  Future<Map<String, dynamic>> getEmployeeDashboardSummary() async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.get(
        Uri.parse('${ApiClient.baseUrl}/employee/dashboard-summary'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('DEBUG: Dashboard API Raw Response: ${response.body}');
        final body = json.decode(response.body);
        if (body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        throw Exception('Format data dashboard tidak valid.');
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Gagal memuat ringkasan dashboard.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }
}
