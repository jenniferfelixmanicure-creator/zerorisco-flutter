import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'zerorisco_token';
  static const _modeKey = 'zerorisco_mode';

  Future<String?> getMode() => _storage.read(key: _modeKey);
  Future<void> saveMode(String mode) => _storage.write(key: _modeKey, value: mode);
  Future<void> clearMode() => _storage.delete(key: _modeKey);

  Future<String?> getSavedToken() => _storage.read(key: _tokenKey);
  Future<void> _saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> _clearToken() => _storage.delete(key: _tokenKey);

  String? _currentToken;
  String? get currentToken => _currentToken;

  Future<void> restoreSession() async {
    _currentToken = await getSavedToken();
  }

  Future<({UserModel user, String token})> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.apiBase}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(ApiConstants.connectTimeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AuthException(body['message'] as String? ?? 'Erro ao fazer login.');
    }

    final token = body['token'] as String;
    final user = UserModel.fromJson(body['user'] as Map<String, dynamic>);

    _currentToken = token;
    await _saveToken(token);

    return (user: user, token: token);
  }

  Future<({UserModel user, String token})> register(
    String name,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.apiBase}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      }),
    ).timeout(ApiConstants.connectTimeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(body['message'] as String? ?? 'Erro ao criar conta.');
    }

    final token = body['token'] as String;
    final user = UserModel.fromJson(body['user'] as Map<String, dynamic>);

    _currentToken = token;
    await _saveToken(token);

    return (user: user, token: token);
  }

  Future<UserModel?> fetchProfile() async {
    final token = _currentToken ?? await getSavedToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBase}/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {}

    return null;
  }

  Future<void> logout() async {
    _currentToken = null;
    await _clearToken();
    await clearMode();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
