import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class NotificationBannerHost extends StatefulWidget {
  final Widget child;
  final NotificationService notificationService;

  const NotificationBannerHost({
    super.key,
    required this.child,
    required this.notificationService,
  });

  @override
  State<NotificationBannerHost> createState() => _NotificationBannerHostState();
}

class _NotificationBannerHostState extends State<NotificationBannerHost> {
  final List<AppNotification> _queue = [];
  AppNotification? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    widget.notificationService.addBannerListener(_onNotification);
  }

  @override
  void dispose() {
    widget.notificationService.removeBannerListener(_onNotification);
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onNotification(AppNotification notif) {
    _queue.add(notif);
    if (_current == null) _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    setState(() => _current = _queue.removeAt(0));
    _dismissTimer?.cancel();
    final duration = _current!.urgent ? 6 : 4;
    _dismissTimer = Timer(Duration(seconds: duration), _showNext);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _showNext();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _BannerCard(
                  notification: _current!,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;

  const _BannerCard({required this.notification, required this.onDismiss});

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: Key(n.id),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              decoration: BoxDecoration(
                color: n.urgent ? const Color(0xFF2D0A0A) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: n.urgent ? AppColors.error : n.color.withOpacity(0.4),
                  width: n.urgent ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: n.color.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: n.color.withOpacity(0.15),
                    ),
                    child: Icon(n.icon, color: n.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          n.title,
                          style: TextStyle(
                            color: n.urgent ? AppColors.error : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (n.body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            n.body,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
