import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/api_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/passenger/providers/passenger_provider.dart';
import 'features/driver/providers/driver_provider.dart';
import 'features/shared/widgets/notification_banner.dart';
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
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(
      authService: _authService,
      socketService: _socketService,
      apiService: _apiService,
    );
    _notificationService = NotificationService(_socketService);
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _notificationService),
        Provider<ApiService>.value(value: _apiService),
        Provider<SocketService>.value(value: _socketService),
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
      // RouterConfig é criado UMA VEZ dentro de um Consumer<AuthProvider>
      // para evitar que rebuilds criem um novo GoRouter
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final router = buildRouter(context);
          return MaterialApp.router(
            title: 'ZeroRisco',
            theme: AppTheme.dark,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: NotificationBannerHost(
                  notificationService: _notificationService,
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
