import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload(String docType) async {
    final source = await _showSourceDialog();
    if (source == null) return;

    final xfile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null) return;

    setState(() => _uploading = true);
    try {
      // Simula upload: em produção, fazer multipart POST para /api/users/me/docs
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docType enviado! Aguardando análise.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar $docType'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Câmera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Tirar foto agora', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Galeria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Escolher da galeria', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final docs = [
      _DocItem(
        code: 'RG',
        label: 'RG — Registro Geral',
        subtitle: 'Frente e verso',
        icon: Icons.badge_rounded,
        status: user?.rgStatus ?? 'pending',
      ),
      _DocItem(
        code: 'CNH',
        label: 'CNH — Carteira de Motorista',
        subtitle: 'Categoria B ou superior',
        icon: Icons.drive_eta_rounded,
        status: user?.cnhStatus ?? 'pending',
      ),
      _DocItem(
        code: 'CRLV',
        label: 'CRLV — Licença do Veículo',
        subtitle: 'Documento do veículo atual',
        icon: Icons.directions_car_rounded,
        status: user?.crlvStatus ?? 'pending',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Meus Documentos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Envie fotos nítidas e legíveis. Os documentos são analisados em até 24h.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...docs.map((doc) => _DocCard(
                    doc: doc,
                    onUpload: _uploading ? null : () => _pickAndUpload(doc.code),
                  )),
            ],
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        const Text('Enviando documento...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocItem {
  final String code, label, subtitle, status;
  final IconData icon;
  const _DocItem({required this.code, required this.label, required this.subtitle, required this.icon, required this.status});
}

class _DocCard extends StatelessWidget {
  final _DocItem doc;
  final VoidCallback? onUpload;
  const _DocCard({required this.doc, required this.onUpload});

  Color get _color => switch (doc.status) {
    'approved' => AppColors.success,
    'rejected' => AppColors.error,
    'under_review' => AppColors.warning,
    _ => AppColors.textMuted,
  };

  String get _statusLabel => switch (doc.status) {
    'approved' => 'Aprovado',
    'rejected' => 'Recusado — reenvie',
    'under_review' => 'Em análise',
    _ => 'Pendente',
  };

  IconData get _statusIcon => switch (doc.status) {
    'approved' => Icons.check_circle_rounded,
    'rejected' => Icons.cancel_rounded,
    'under_review' => Icons.hourglass_bottom_rounded,
    _ => Icons.upload_file_rounded,
  };

  bool get _canUpload => doc.status == 'pending' || doc.status == 'rejected';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color.withOpacity(0.12),
                  ),
                  child: Icon(doc.icon, color: _color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(doc.subtitle,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(_statusIcon, color: _color, size: 16),
                const SizedBox(width: 8),
                Text(_statusLabel,
                    style: TextStyle(color: _color, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_canUpload)
                  TextButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Enviar foto'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
