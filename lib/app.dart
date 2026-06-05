import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/passenger/providers/passenger_provider.dart';
import 'features/driver/providers/driver_provider.dart';
import 'router/app_router.dart';

class ZeroRiscoApp extends StatefulWidget {
  const ZeroRiscoApp({super.key});

  @override
  State<ZeroRiscoApp> createState() => _ZeroRiscoAppState();
}

class _ZeroRiscoAppState extends State<ZeroRiscoApp> {
  final _authService = AuthService();
  final _socketService = SocketService();
  final _apiService = ApiService();
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(
      authService: _authService,
      socketService: _socketService,
      apiService: _apiService,
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider(
          create: (_) => PassengerProvider(
            socket: _socketService,
            api: _apiService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DriverProvider(
            socket: _socketService,
            api: _apiService,
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context);
          return MaterialApp.router(
            title: 'ZeroRisco',
            theme: AppTheme.dark,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
