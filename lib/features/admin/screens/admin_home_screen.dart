import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBase}/admin/stats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _stats = jsonDecode(res.body) as Map<String, dynamic>;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifService = context.watch<NotificationService>();
    final user = auth.user;
    final pendingDrivers = (_stats?['pendingDrivers'] ?? 0) as int;
    final unread = notifService.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Painel ZeroRisco', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          ),
          // Badge de notificações
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
              ),
              if (unread > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => context.push('/admin/profile'),
            icon: const Icon(Icons.account_circle_rounded, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Olá, ${user?.name.split(' ').first ?? 'Admin'} 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Visão geral da plataforma',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('RESUMO'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    children: [
                      _statCard('Usuários', '${_stats?['totalUsers'] ?? 0}', Icons.people_rounded, AppColors.primary),
                      _statCard('Motoristas', '${_stats?['totalDrivers'] ?? 0}', Icons.drive_eta_rounded, AppColors.accent),
                      _statCard('Pendentes', '$pendingDrivers', Icons.pending_rounded, AppColors.warning),
                      _statCard('Corridas ativas', '${_stats?['activeRides'] ?? 0}', Icons.route_rounded, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('AÇÕES RÁPIDAS'),
                  const SizedBox(height: 12),
                  _actionTile(
                    context,
                    icon: Icons.person_search_rounded,
                    label: 'Motoristas',
                    subtitle: pendingDrivers > 0
                        ? '$pendingDrivers aguardando aprovação'
                        : 'Gerenciar motoristas',
                    badge: pendingDrivers > 0 ? pendingDrivers : null,
                    onTap: () => context.push('/admin/drivers'),
                  ),
                  _actionTile(
                    context,
                    icon: Icons.group_rounded,
                    label: 'Usuários',
                    subtitle: '${_stats?['totalUsers'] ?? 0} cadastrados',
                    onTap: () => context.push('/admin/users'),
                  ),
                  _actionTile(
                    context,
                    icon: Icons.route_rounded,
                    label: 'Corridas',
                    subtitle: '${_stats?['totalRides'] ?? 0} no total',
                    onTap: () => context.push('/admin/rides'),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(height: 8),
                    _actionTile(
                      context,
                      icon: Icons.notifications_active_rounded,
                      label: 'Notificações',
                      subtitle: '$unread novas notificações',
                      badge: unread,
                      color: AppColors.error,
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    int? badge,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badge != null ? c.withOpacity(0.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
