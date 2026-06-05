import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<http.Response> get(String path) => http.get(
    Uri.parse('${ApiConstants.apiBase}$path'),
    headers: _headers,
  ).timeout(ApiConstants.receiveTimeout);

  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      http.post(
        Uri.parse('${ApiConstants.apiBase}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(ApiConstants.receiveTimeout);

  Future<http.Response> put(String path, Map<String, dynamic> body) =>
      http.put(
        Uri.parse('${ApiConstants.apiBase}$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(ApiConstants.receiveTimeout);

  Future<dynamic> getJson(String path) async {
    final res = await get(path);
    return jsonDecode(res.body);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final res = await post(path, body);
    return jsonDecode(res.body);
  }

  Future<void> validatePromoCode(String code) async {
    final res = await post('/rides/promo/validate', {'code': code});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Código inválido');
    }
  }

  Future<void> submitRating({
    required String rideId,
    required int ratedId,
    required int stars,
    required String role,
  }) async {
    await post('/ratings', {
      'rideId': rideId,
      'ratedId': ratedId,
      'stars': stars,
      'role': role,
    });
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    return await getJson('/rides/driver/stats') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRidesHistory({
    int limit = 20,
    String? cursor,
    bool isDriver = false,
  }) async {
    final path = isDriver ? '/rides/driver/history' : '/rides/history';
    var url = '$path?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    return await getJson(url) as Map<String, dynamic>;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await put('/users/me', data);
  }
}
