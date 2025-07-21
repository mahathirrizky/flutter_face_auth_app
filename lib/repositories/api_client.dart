import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient extends http.BaseClient {
  static const String baseUrl = 'https://api.4commander.my.id/api';
  final http.Client _inner;

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

      // Lemparkan pengecualian untuk ditangani oleh BLoC
      throw Exception('Session expired');
    }

    return response;
  }
}
