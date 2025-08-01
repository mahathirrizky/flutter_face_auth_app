import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
class AuthRepository {
 

  AuthRepository();

  Future<String> loginEmployee(String email, String password) async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.post(
        Uri.parse('${ApiClient.baseUrl}/login/employee'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null && body['data']['token'] != null) {
          final token = body['data']['token'] as String;
          print('DEBUG: Received JWT Token: $token');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          return token;
        } else {
          throw Exception('Token tidak ditemukan dalam respons.');
        }
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Terjadi kesalahan saat login.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
