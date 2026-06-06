import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final notifs = service.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Notificações', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (notifs.isNotEmpty)
            TextButton(
              onPressed: service.clearAll,
              child: Text('Limpar', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: notifs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 72, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('Nenhuma notificação', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifs[i];
                return Container(
                  decoration: BoxDecoration(
                    color: n.read ? AppColors.card : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: n.read ? AppColors.border : n.color.withOpacity(0.35),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: n.color.withOpacity(0.12),
                      ),
                      child: Icon(n.icon, color: n.color, size: 22),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(n.body, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(n.timestamp),
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    trailing: !n.read
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: n.color),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}
