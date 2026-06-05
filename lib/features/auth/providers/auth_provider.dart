import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/api_service.dart';

enum AuthState { loading, unauthenticated, modeSelection, passenger, driver }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SocketService _socketService;
  final ApiService _apiService;

  UserModel? _user;
  String? _token;
  String? _mode;
  AuthState _state = AuthState.loading;
  String? _error;

  AuthProvider({
    required AuthService authService,
    required SocketService socketService,
    required ApiService apiService,
  })  : _authService = authService,
        _socketService = socketService,
        _apiService = apiService;

  UserModel? get user => _user;
  String? get token => _token;
  String? get mode => _mode;
  AuthState get state => _state;
  String? get error => _error;
  bool get isPassenger => _mode == 'passenger';
  bool get isDriver => _mode == 'driver';

  Future<void> initialize() async {
    try {
      final session = _authService.currentSession;
      if (session == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      _token = session.accessToken;
      _apiService.setToken(_token);

      // Timeout de 5 segundos para buscar o perfil, caso o Supabase demore a responder
      final user = await _authService.fetchProfile().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout ao carregar perfil'),
      );
      
      if (user == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      _user = user;
      _socketService.connect(_token!);

      final savedMode = await _authService.getMode();
      _mode = savedMode;
      _state = _resolveState(savedMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro na inicialização: $e');
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  AuthState _resolveState(String? mode) {
    if (mode == null) return AuthState.modeSelection;
    return mode == 'driver' ? AuthState.driver : AuthState.passenger;
  }

  Future<void> login(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.login(email, password);
      _user = result.user;
      _token = result.token;
      _apiService.setToken(_token);
      _socketService.connect(_token!);

      final savedMode = await _authService.getMode();
      _mode = savedMode;
      _state = _resolveState(savedMode);
      notifyListeners();
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Erro de conexão. Verifique sua internet.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
    String role,
  ) async {
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.register(name, email, phone, password, role);
      _user = result.user;
      _token = result.token;
      _apiService.setToken(_token);
      if (_token!.isNotEmpty) {
        _socketService.connect(_token!);
      }
      _state = AuthState.modeSelection;
      notifyListeners();
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Erro ao criar conta. Tente novamente.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setMode(String mode) async {
    _mode = mode;
    await _authService.saveMode(mode);
    _state = mode == 'driver' ? AuthState.driver : AuthState.passenger;
    notifyListeners();
  }

  Future<void> logout() async {
    _socketService.disconnect();
    await _authService.logout();
    _user = null;
    _token = null;
    _mode = null;
    _apiService.setToken(null);
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void updateUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
