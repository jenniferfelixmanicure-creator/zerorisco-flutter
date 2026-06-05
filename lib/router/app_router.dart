import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/mode_selection_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/passenger/screens/passenger_home_screen.dart';
import '../features/passenger/screens/passenger_history_screen.dart';
import '../features/passenger/screens/passenger_profile_screen.dart';
import '../features/driver/screens/driver_home_screen.dart';
import '../features/driver/screens/driver_earnings_screen.dart';
import '../features/driver/screens/driver_profile_screen.dart';

GoRouter buildRouter(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.matchedLocation;
      switch (auth.state) {
        case AuthState.loading:
          return '/splash';
        case AuthState.unauthenticated:
          if (path == '/splash' || path == '/login' || path == '/register') {
            return null;
          }
          return '/login';
        case AuthState.modeSelection:
          return '/mode';
        case AuthState.passenger:
          if (path.startsWith('/passenger')) return null;
          return '/passenger';
        case AuthState.driver:
          if (path.startsWith('/driver')) return null;
          return '/driver';
      }
    },
    refreshListenable: auth,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (_, __) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/mode',
        builder: (_, __) => const ModeSelectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _PassengerShell(child: child),
        routes: [
          GoRoute(
            path: '/passenger',
            builder: (_, __) => const PassengerHomeScreen(),
          ),
          GoRoute(
            path: '/passenger/history',
            builder: (_, __) => const PassengerHistoryScreen(),
          ),
          GoRoute(
            path: '/passenger/profile',
            builder: (_, __) => const PassengerProfileScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => _DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/driver',
            builder: (_, __) => const DriverHomeScreen(),
          ),
          GoRoute(
            path: '/driver/earnings',
            builder: (_, __) => const DriverEarningsScreen(),
          ),
          GoRoute(
            path: '/driver/profile',
            builder: (_, __) => const DriverProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Center(
        child: Text(
          'Página não encontrada: ${state.error}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}

class _PassengerShell extends StatelessWidget {
  final Widget child;
  const _PassengerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _DriverShell extends StatelessWidget {
  final Widget child;
  const _DriverShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
