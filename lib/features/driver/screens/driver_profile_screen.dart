import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Meu perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => auth.logout(),
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildAvatar(user?.name ?? '?'),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user?.isApproved == true
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user?.isApproved == true
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                user?.isApproved == true ? 'Aprovado' : 'Aguardando aprovação',
                style: TextStyle(
                  color: user?.isApproved == true ? AppColors.success : AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  user?.driverRating.toStringAsFixed(1) ?? '5.0',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Text('•', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: 12),
                Text(
                  '${user?.totalRides ?? 0} corridas',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _sectionTitle('DADOS PESSOAIS'),
            const SizedBox(height: 12),
            _tile(Icons.phone_rounded, 'Telefone', user?.phone ?? '—'),
            _tile(Icons.email_rounded, 'E-mail', user?.email ?? '—'),
            const SizedBox(height: 24),
            _sectionTitle('VEÍCULO'),
            const SizedBox(height: 12),
            _tile(Icons.directions_car_rounded, 'Modelo', user?.vehicleModel ?? 'Não cadastrado'),
            _tile(Icons.palette_rounded, 'Cor', user?.vehicleColor ?? 'Não cadastrado'),
            _tile(Icons.pin_rounded, 'Placa', user?.vehiclePlate ?? 'Não cadastrado'),
            _tile(Icons.category_rounded, 'Tipo', user?.vehicleType ?? 'Não cadastrado'),
            const SizedBox(height: 24),
            _sectionTitle('DOCUMENTOS'),
            const SizedBox(height: 12),
            _docTile('RG', user?.rgStatus ?? 'pending'),
            _docTile('CNH', user?.cnhStatus ?? 'pending'),
            _docTile('CRLV', user?.crlvStatus ?? 'pending'),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => auth.setMode('passenger'),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Mudar para modo passageiro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase();
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docTile(String doc, String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'Aprovado';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Recusado';
        icon = Icons.cancel_rounded;
        break;
      case 'under_review':
        color = AppColors.warning;
        label = 'Em análise';
        icon = Icons.hourglass_bottom_rounded;
        break;
      default:
        color = AppColors.textMuted;
        label = 'Pendente';
        icon = Icons.upload_file_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              doc,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
