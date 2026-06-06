import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _approved = [];
  List<Map<String, dynamic>> _suspended = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    try {
      final results = await Future.wait([
        _fetch(token!, 'pending'),
        _fetch(token, 'approved'),
        _fetch(token, 'suspended'),
      ]);
      if (mounted) {
        setState(() {
          _pending = results[0];
          _approved = results[1];
          _suspended = results[2];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetch(String token, String status) async {
    final res = await http.get(
      Uri.parse('${ApiConstants.apiBase}/admin/drivers?status=$status&limit=50'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
    }
    return [];
  }

  Future<void> _approve(String id) async {
    final token = context.read<AuthProvider>().token;
    final res = await http.post(
      Uri.parse('${ApiConstants.apiBase}/admin/drivers/$id/approve'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      _showSnack('Motorista aprovado!', AppColors.success);
      _load();
    }
  }

  Future<void> _suspend(String id) async {
    final token = context.read<AuthProvider>().token;
    final res = await http.post(
      Uri.parse('${ApiConstants.apiBase}/admin/users/$id/suspend'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      _showSnack('Usuário suspenso.', AppColors.warning);
      _load();
    }
  }

  Future<void> _unsuspend(String id) async {
    final token = context.read<AuthProvider>().token;
    final res = await http.post(
      Uri.parse('${ApiConstants.apiBase}/admin/users/$id/unsuspend'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      _showSnack('Suspensão removida.', AppColors.success);
      _load();
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Motoristas'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: 'Pendentes (${_pending.length})'),
            Tab(text: 'Aprovados (${_approved.length})'),
            Tab(text: 'Suspensos (${_suspended.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(_pending, showApprove: true, showSuspend: true),
                _buildList(_approved, showSuspend: true),
                _buildList(_suspended, showUnsuspend: true),
              ],
            ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> drivers, {
    bool showApprove = false,
    bool showSuspend = false,
    bool showUnsuspend = false,
  }) {
    if (drivers.isEmpty) {
      return Center(
        child: Text('Nenhum motorista aqui.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (_, i) => _driverCard(
          drivers[i],
          showApprove: showApprove,
          showSuspend: showSuspend,
          showUnsuspend: showUnsuspend,
        ),
      ),
    );
  }

  Widget _driverCard(
    Map<String, dynamic> d, {
    bool showApprove = false,
    bool showSuspend = false,
    bool showUnsuspend = false,
  }) {
    final id = d['id'] as String;
    final name = d['name'] as String? ?? '—';
    final email = d['email'] as String? ?? '—';
    final plate = d['vehiclePlate'] as String? ?? 'Sem placa';
    final model = d['vehicleModel'] as String? ?? 'Sem modelo';
    final rating = ((d['driverRating'] ?? 5.0) as num).toDouble();
    final rides = (d['totalRides'] ?? 0) as int;

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
              _avatar(name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(email, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _chip(Icons.directions_car_rounded, '$model • $plate'),
              _chip(Icons.route_rounded, '$rides corridas'),
            ],
          ),
          if (showApprove || showSuspend || showUnsuspend) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (showApprove)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Aprovar', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                if (showApprove && showSuspend) const SizedBox(width: 8),
                if (showSuspend)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _suspend(id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.block_rounded, size: 16),
                      label: const Text('Suspender', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                if (showUnsuspend)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _unsuspend(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 40),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Reativar'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String name) {
    final initials = name.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
