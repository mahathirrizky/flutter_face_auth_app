import 'dart:convert';
import 'package:flutter_face_auth_app/helper/custom_exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_face_auth_app/repositories/api_client.dart';
import 'package:flutter_face_auth_app/bloc/bloc.dart'; // Import Announcement model

class AnnouncementRepository {
  final String _baseUrl = 'https://api.4commander.my.id/api';

  AnnouncementRepository();

  Future<List<Announcement>> getAnnouncements() async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/broadcasts'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null) {
          final List<dynamic> data = body['data'];
          return data.map((json) => Announcement.fromJson(json)).toList();
        }
        throw CustomException('Format data pengumuman tidak valid.');
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Gagal memuat pengumuman.';
        throw Exception(errorMessage);
      }
    } finally {
      client.close();
    }
  }

  Future<void> markAsRead(int messageId) async {
    final client = ApiClient(http.Client());
    try {
      final response = await client.post(
        Uri.parse('${ApiClient.baseUrl}/broadcasts/$messageId/read'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Gagal menandai sebagai sudah dibaca.';
        throw Exception(errorMessage);
      }
    } finally {
      client.close();
    }
  }
}
