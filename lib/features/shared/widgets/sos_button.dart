import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onActivated;

  const SosButton({super.key, required this.onActivated});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _progressAnim = CurvedAnimation(parent: _pressCtrl, curve: Curves.linear);
    _pressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSOS();
      }
    });
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _triggerSOS() {
    HapticFeedback.heavyImpact();
    widget.onActivated();
    _showSOSDialog();
    _pressCtrl.reset();
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SOSDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 140,
      child: GestureDetector(
        onLongPressStart: (_) {
          HapticFeedback.mediumImpact();
          _pressCtrl.forward();
        },
        onLongPressEnd: (_) {
          if (_pressCtrl.status != AnimationStatus.completed) {
            _pressCtrl.reverse();
          }
        },
        onLongPressCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield, color: Colors.white, size: 22),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_progressAnim.value > 0)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: _progressAnim.value,
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_pressCtrl.isAnimating) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Segure 2s…',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SOSDialog extends StatelessWidget {
  const _SOSDialog();

  Future<void> _call(BuildContext context, String number) async {
    Navigator.of(context).pop();
    await launchUrl(Uri.parse('tel:$number'));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.error, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'SOS — Emergência',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Alerta enviado para a central. Selecione o serviço de emergência:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _EmergencyBtn(
              color: const Color(0xFF1C3A8A),
              icon: Icons.shield,
              label: 'Polícia Militar',
              number: '190',
              onTap: () => _call(context, '190'),
            ),
            const SizedBox(height: 10),
            _EmergencyBtn(
              color: const Color(0xFFC0392B),
              icon: Icons.favorite_rounded,
              label: 'SAMU — Ambulância',
              number: '192',
              onTap: () => _call(context, '192'),
            ),
            const SizedBox(height: 10),
            _EmergencyBtn(
              color: const Color(0xFFE67E22),
              icon: Icons.fireplace_rounded,
              label: 'Corpo de Bombeiros',
              number: '193',
              onTap: () => _call(context, '193'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Center(
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String number;
  final VoidCallback onTap;

  const _EmergencyBtn({
    required this.color,
    required this.icon,
    required this.label,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
