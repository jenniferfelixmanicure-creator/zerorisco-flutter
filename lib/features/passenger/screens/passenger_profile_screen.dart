import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;

  Future<void> _pickPhoto() async {
    final source = await _showSourceDialog();
    if (source == null) return;
    final xfile = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 512);
    if (xfile == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      // Em produção: upload para storage e atualizar profilePhotoUrl via API
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto de perfil atualizada!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<ImageSource?> _showSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Câmera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Galeria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifService = context.watch<NotificationService>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
              if (notifService.unreadCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                    child: Text(
                      '${notifService.unreadCount}',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
            // Avatar com botão de editar foto
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                children: [
                  _buildAvatar(user?.name ?? '?', user?.profilePhotoUrl),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: _uploadingPhoto
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '—',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text(user?.email ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  user?.passengerRating.toStringAsFixed(1) ?? '5.0',
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
            _tile(Icons.phone_rounded, 'Telefone', user?.phone ?? '—'),
            _tile(Icons.email_rounded, 'E-mail', user?.email ?? '—'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.setMode('driver'),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Trocar para modo motorista'),
              ),
            ),
            if (auth.isAdmin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => auth.backToAdmin(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                  label: const Text('Voltar ao painel admin'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 45,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: AppColors.card,
      );
    }
    final initials = name.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join().toUpperCase();
    return Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Center(
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
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
}
