import 'package:flutter/material.dart';
import 'socket_service.dart';

enum NotificationType { rideAccepted, rideStarted, rideCompleted, rideCancelled, newDriver, emergency, chat, generic }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final bool urgent;
  final String? rideId;
  final DateTime timestamp;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.urgent = false,
    this.rideId,
    required this.timestamp,
    this.read = false,
  });

  factory AppNotification.fromSocket(Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'generic';
    final type = switch (typeStr) {
      'ride_accepted' => NotificationType.rideAccepted,
      'ride_started' => NotificationType.rideStarted,
      'ride_completed' => NotificationType.rideCompleted,
      'ride_cancelled' => NotificationType.rideCancelled,
      'new_driver' => NotificationType.newDriver,
      'emergency' => NotificationType.emergency,
      _ => NotificationType.generic,
    };

    return AppNotification(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: data['title'] as String? ?? 'Notificação',
      body: data['body'] as String? ?? '',
      urgent: data['urgent'] == true,
      rideId: data['rideId'] as String?,
      timestamp: DateTime.now(),
    );
  }

  IconData get icon => switch (type) {
    NotificationType.rideAccepted => Icons.directions_car_rounded,
    NotificationType.rideStarted => Icons.play_circle_rounded,
    NotificationType.rideCompleted => Icons.check_circle_rounded,
    NotificationType.rideCancelled => Icons.cancel_rounded,
    NotificationType.newDriver => Icons.person_add_rounded,
    NotificationType.emergency => Icons.warning_rounded,
    NotificationType.chat => Icons.chat_rounded,
    NotificationType.generic => Icons.notifications_rounded,
  };

  Color get color => switch (type) {
    NotificationType.rideAccepted => const Color(0xFF00C896),
    NotificationType.rideStarted => const Color(0xFF3B82F6),
    NotificationType.rideCompleted => const Color(0xFF00C896),
    NotificationType.rideCancelled => const Color(0xFFEF4444),
    NotificationType.newDriver => const Color(0xFF8B5CF6),
    NotificationType.emergency => const Color(0xFFEF4444),
    NotificationType.chat => const Color(0xFF3B82F6),
    NotificationType.generic => const Color(0xFF6B7280),
  };
}

class NotificationService extends ChangeNotifier {
  final SocketService _socketService;
  final List<AppNotification> _notifications = [];
  final List<void Function(AppNotification)> _onShowBanner = [];

  NotificationService(this._socketService) {
    _socketService.on('notification', _handleNotification);
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  void _handleNotification(dynamic data) {
    if (data is! Map) return;
    final notif = AppNotification.fromSocket(Map<String, dynamic>.from(data));
    _notifications.insert(0, notif);
    if (_notifications.length > 100) _notifications.removeRange(100, _notifications.length);

    for (final cb in _onShowBanner) {
      cb(notif);
    }
    notifyListeners();
  }

  void addBannerListener(void Function(AppNotification) cb) {
    _onShowBanner.add(cb);
  }

  void removeBannerListener(void Function(AppNotification) cb) {
    _onShowBanner.remove(cb);
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx].read = true;
      notifyListeners();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.off('notification', _handleNotification);
    super.dispose();
  }
}
