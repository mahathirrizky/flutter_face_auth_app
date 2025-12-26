import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
class ProfileRepository {
  final String _baseUrl = 'https://457c68305f78.ngrok-free.app/api';

  ProfileRepository();

  Future<Map<String, dynamic>> getEmployeeProfile() async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/employee/profile'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        throw Exception('Invalid profile data format.');
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load profile.';
        print('DEBUG: Profile API Error: ${response.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<void> uploadFaceImage(Uint8List imageBytes, String filename) async {
    final client = ApiClient(http.Client());
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/employee/register-face'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'face_image',
        imageBytes,
        filename: filename,
        contentType: MediaType('image', filename.split('.').last),
      ));

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success codes are typically 2xx
        return;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to upload face image.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<void> updateEmployeeProfile({
    required String name,
    required String email,
    required String position,
  }) async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.put(
        Uri.parse('$_baseUrl/employee/profile'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'position': position,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to update profile.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<void> changeEmployeePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.put(
        Uri.parse('$_baseUrl/employee/change-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_new_password': confirmNewPassword,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to change password.';
        throw CustomException(errorMessage);
      }
    } finally {
      client.close();
    }
  }
}