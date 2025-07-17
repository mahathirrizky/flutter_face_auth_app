import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_face_auth_app/app_router.dart'; // Import app_router for rootNavigatorKey

class ApiClient extends http.BaseClient {
  static const String baseUrl = 'https://api.4commander.my.id/api';
  final http.Client _inner;
  // Removed BuildContext context; as it's no longer needed for navigation

  ApiClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      // Hapus token
      await prefs.remove('token');

      // Arahkan ke halaman login menggunakan instance GoRouter global
      appRouter.go('/login');
    }

    return response;
  }
}
