import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class PassengerHistoryScreen extends StatefulWidget {
  const PassengerHistoryScreen({super.key});

  @override
  State<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final api = context.read<ApiService>();
    try {
      final data = await api.getRidesHistory(limit: 30);
      final rides = (data['rides'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _rides = rides; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Histórico de corridas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ))
          : _rides.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _rides.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RideHistoryCard(ride: _rides[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, color: AppColors.textMuted, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma corrida ainda',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas corridas vão aparecer aqui',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  const _RideHistoryCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as String? ?? '';
    final price = (ride['price'] ?? 0).toDouble();
    final origin = ride['origin'] as Map<String, dynamic>? ?? {};
    final destination = ride['destination'] as Map<String, dynamic>? ?? {};
    final rideType = ride['rideType'] as String? ?? 'basico';
    final createdAt = ride['createdAt'] as String? ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Concluída';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Cancelada';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = status;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'R\$ ${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.circle, AppColors.primary, origin['address'] as String? ?? '—'),
          const SizedBox(height: 8),
          _row(Icons.location_pin, AppColors.error, destination['address'] as String? ?? '—'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                rideType,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              if (createdAt.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text('•', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: 12),
                Text(
                  createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
