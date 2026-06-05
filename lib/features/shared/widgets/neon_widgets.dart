import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Fundo com padrão de circuito eletrônico
class CircuitBackground extends StatelessWidget {
  const CircuitBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _CircuitPainter()),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF0A2040).withOpacity(0.5)
      ..strokeWidth = 0.6;

    final dotPaint = Paint()
      ..color = const Color(0xFF0A3060).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    final rng = math.Random(42);
    final w = size.width;
    final h = size.height;

    for (double x = 0; x <= w; x += spacing) {
      for (double y = 0; y <= h; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        if (rng.nextBool() && x + spacing <= w) {
          canvas.drawLine(Offset(x, y), Offset(x + spacing, y), linePaint);
        }
        if (rng.nextBool() && y + spacing <= h) {
          canvas.drawLine(Offset(x, y), Offset(x, y + spacing), linePaint);
        }
      }
    }

    final glowDotPaint = Paint()
      ..color = const Color(0xFF00B4FF).withOpacity(0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final hotspots = [
      Offset(w * 0.15, h * 0.25),
      Offset(w * 0.85, h * 0.15),
      Offset(w * 0.75, h * 0.72),
      Offset(w * 0.20, h * 0.80),
    ];
    for (final o in hotspots) {
      canvas.drawCircle(o, 3.5, glowDotPaint);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => false;
}

// Campo de texto estilo neon
class NeonField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const NeonField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<NeonField> createState() => _NeonFieldState();
}

class _NeonFieldState extends State<NeonField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF00B4FF).withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF07121E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Icon(widget.icon, color: const Color(0xFF00B4FF), size: 20),
            suffixIcon: widget.suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.suffixIcon,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _focused
                    ? const Color(0xFF00B4FF)
                    : const Color(0xFF00B4FF).withOpacity(0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF00B4FF).withOpacity(0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00B4FF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// Botão estilo neon com bordas chanfradas
class NeonButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const NeonButton({
    super.key,
    required this.label,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: loading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF07121E),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF00B4FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B4FF).withOpacity(0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF00B4FF).withOpacity(0.1),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipPath(
            clipper: BevelClipper(bevel: 10),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF00B4FF)),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.double_arrow_rounded,
                            color: Color(0xFF00B4FF),
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BevelClipper extends CustomClipper<Path> {
  final double bevel;
  const BevelClipper({required this.bevel});

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(bevel, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - bevel)
      ..lineTo(size.width - bevel, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, bevel)
      ..close();
  }

  @override
  bool shouldReclip(BevelClipper old) => old.bevel != bevel;
}
