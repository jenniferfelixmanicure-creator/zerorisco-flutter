import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
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
        Uri.parse('${ApiConstants.apiBase}/admin/users?role=passenger&limit=50'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(jsonDecode(res.body) as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suspend(String id) async {
    final token = context.read<AuthProvider>().token;
    await http.post(
      Uri.parse('${ApiConstants.apiBase}/admin/users/$id/suspend'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _showSnack('Usuário suspenso.', AppColors.warning);
    _load();
  }

  Future<void> _unsuspend(String id) async {
    final token = context.read<AuthProvider>().token;
    await http.post(
      Uri.parse('${ApiConstants.apiBase}/admin/users/$id/unsuspend'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _showSnack('Suspensão removida.', AppColors.success);
    _load();
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
        title: const Text('Passageiros'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              child: _users.isEmpty
                  ? const Center(
                      child: Text('Nenhum passageiro cadastrado.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (_, i) => _userCard(_users[i]),
                    ),
            ),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final id = u['id'] as String;
    final name = u['name'] as String? ?? '—';
    final email = u['email'] as String? ?? '—';
    final phone = u['phone'] as String? ?? '—';
    final suspended = u['suspended'] as bool? ?? false;
    final rides = (u['totalRides'] ?? 0) as int;
    final rating = ((u['passengerRating'] ?? 5.0) as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: suspended ? AppColors.error.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('$rides corridas',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (suspended)
            GestureDetector(
              onTap: () => _unsuspend(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.4)),
                ),
                child: const Text('Reativar',
                    style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )
          else
            GestureDetector(
              onTap: () => _suspend(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Text('Suspender',
                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
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
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
