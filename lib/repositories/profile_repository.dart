import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_client.dart';

class ProfileRepository {
  final String _baseUrl = 'https://api.4commander.my.id/api';

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
        Uri.parse('$_baseUrl/employee/register-face'),
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
        throw Exception(errorMessage);
      }
    } finally {
      client.close();
    }
  }
}
