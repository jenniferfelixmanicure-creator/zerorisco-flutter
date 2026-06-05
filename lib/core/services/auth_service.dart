import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _modeKey = 'zerorisco_mode';

  Future<String?> getMode() => _storage.read(key: _modeKey);
  Future<void> saveMode(String mode) => _storage.write(key: _modeKey, value: mode);
  Future<void> clearMode() => _storage.delete(key: _modeKey);

  Session? get currentSession => _supabase.auth.currentSession;
  String? get currentToken => _supabase.auth.currentSession?.accessToken;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<({UserModel user, String token})> login(
    String email,
    String password,
  ) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.session == null) {
      throw AuthException('Credenciais inválidas. Verifique e-mail e senha.');
    }

    final token = res.session!.accessToken;
    final user = await _fetchOrCreateProfile(token, res.user!);
    return (user: user, token: token);
  }

  Future<({UserModel user, String token})> register(
    String name,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
        'role': role,
      },
    );

    if (res.session == null && res.user == null) {
      throw AuthException('Erro ao criar conta. Tente novamente.');
    }

    final token = res.session?.accessToken ?? '';
    final user = await _createBackendProfile(
      token: token,
      supabaseUser: res.user!,
      name: name,
      phone: phone,
      role: role,
    );
    return (user: user, token: token);
  }

  Future<UserModel> _fetchOrCreateProfile(String token, User supabaseUser) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBase}/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 404) {
        final meta = supabaseUser.userMetadata ?? {};
        return await _createBackendProfile(
          token: token,
          supabaseUser: supabaseUser,
          name: meta['name'] as String? ?? supabaseUser.email!.split('@').first,
          phone: meta['phone'] as String? ?? '',
          role: meta['role'] as String? ?? 'passenger',
        );
      }
    } catch (_) {}

    final meta = supabaseUser.userMetadata ?? {};
    return UserModel(
      id: supabaseUser.id,
      name: meta['name'] as String? ?? supabaseUser.email!.split('@').first,
      email: supabaseUser.email ?? '',
      phone: meta['phone'] as String? ?? '',
      role: meta['role'] as String? ?? 'passenger',
    );
  }

  Future<UserModel> _createBackendProfile({
    required String token,
    required User supabaseUser,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.apiBase}/users/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'supabaseId': supabaseUser.id,
          'email': supabaseUser.email,
          'name': name,
          'phone': phone,
          'role': role,
        }),
      ).timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {}

    return UserModel(
      id: supabaseUser.id,
      name: name,
      email: supabaseUser.email ?? '',
      phone: phone,
      role: role,
    );
  }

  Future<UserModel?> fetchProfile() async {
    final token = currentToken;
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.apiBase}/users/me'),
        headers: {'Authorization': 'Bearer $token'},
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
    await _supabase.auth.signOut();
    await clearMode();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
