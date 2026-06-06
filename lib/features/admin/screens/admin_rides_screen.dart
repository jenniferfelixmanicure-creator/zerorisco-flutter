import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AdminRidesScreen extends StatefulWidget {
  const AdminRidesScreen({super.key});

  @override
  State<AdminRidesScreen> createState() => _AdminRidesScreenState();
}

class _AdminRidesScreenState extends State<AdminRidesScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBase}/admin/rides?limit=30'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _rides = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
          _loading = false;
        });
      }
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
        title: const Text('Corridas recentes'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              child: _rides.isEmpty
                  ? const Center(
                      child: Text('Nenhuma corrida ainda.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rides.length,
                      itemBuilder: (_, i) => _rideCard(_rides[i]),
                    ),
            ),
    );
  }

  Widget _rideCard(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'finding';
    final rideType = r['rideType'] as String? ?? '—';
    final price = ((r['price'] ?? 0) as num).toDouble();
    final distance = r['distance'] as String? ?? '—';
    final duration = r['duration'] as String? ?? '—';
    final origin = (r['origin'] as Map<String, dynamic>?)?['address'] as String? ?? '—';
    final destination = (r['destination'] as Map<String, dynamic>?)?['address'] as String? ?? '—';
    final createdAt = r['createdAt'] as String? ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        statusLabel = 'Concluída';
        break;
      case 'in_progress':
        statusColor = AppColors.primary;
        statusLabel = 'Em andamento';
        break;
      case 'driver_coming':
        statusColor = AppColors.accent;
        statusLabel = 'Motorista a caminho';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusLabel = 'Cancelada';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Buscando motorista';
    }

    final typeLabel = {
      'moto': 'ZeroFlash',
      'basico': 'ZeroRisk',
      'intermediario': 'ZeroPlus',
      'vip': 'ZeroGold',
    }[rideType] ?? rideType;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(typeLabel,
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(
                'R\$ ${price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _locationRow(Icons.radio_button_checked_rounded, AppColors.success, origin),
          const SizedBox(height: 6),
          _locationRow(Icons.location_on_rounded, AppColors.error, destination),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip(Icons.straighten_rounded, distance),
              const SizedBox(width: 8),
              _infoChip(Icons.timer_rounded, duration),
              const Spacer(),
              if (createdAt.isNotEmpty)
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
