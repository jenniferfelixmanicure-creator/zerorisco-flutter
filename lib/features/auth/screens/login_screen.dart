import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _fadeCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _glowCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    } catch (e) {
      if (mounted) {
        _showErro(e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04090F),
      body: Stack(
        children: [
          const _CircuitBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, child) => _ShieldLogo(glowIntensity: _glowAnim.value),
                    ),
                    const SizedBox(height: 20),
                    _buildBrand(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 6),
                    _buildRememberRow(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 32),
                    _buildRegisterLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1),
            children: [
              TextSpan(text: 'Zero', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Risco', style: TextStyle(color: Color(0xFF00B4FF))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 30, height: 1, color: const Color(0xFF00B4FF).withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'VIAJE SEGURO. CHEGUE SEGURO.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 30, height: 1, color: const Color(0xFF00B4FF).withValues(alpha: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('E-MAIL'),
          const SizedBox(height: 6),
          _NeonField(
            controller: _emailCtrl,
            hint: 'Digite seu e-mail',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe o e-mail';
              if (!RegExp(r'.+@.+\..+').hasMatch(v)) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _fieldLabel('SENHA'),
          const SizedBox(height: 6),
          _NeonField(
            controller: _passCtrl,
            hint: 'Digite sua senha',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF00B4FF),
                size: 20,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe a senha';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF00B4FF),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildRememberRow() {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Esqueceu a senha?',
            style: TextStyle(
              color: Color(0xFF00B4FF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return _NeonButton(
      label: 'ENTRAR',
      loading: _loading,
      onTap: _loading ? null : _submit,
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Não tem conta?  ',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: const Text(
            'Cadastre-se',
            style: TextStyle(
              color: Color(0xFF00B4FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShieldLogo extends StatelessWidget {
  final double glowIntensity;
  const _ShieldLogo({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    final glow = 0.5 + glowIntensity * 0.5;
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _ShieldPainter(glowIntensity: glow),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final double glowIntensity;
  _ShieldPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const neon = Color(0xFF00B4FF);

    final shieldPath = Path();
    shieldPath.moveTo(cx, size.height * 0.04);
    shieldPath.lineTo(size.width * 0.96, size.height * 0.22);
    shieldPath.lineTo(size.width * 0.96, size.height * 0.58);
    shieldPath.quadraticBezierTo(
      size.width * 0.96, size.height * 0.85,
      cx, size.height * 0.97,
    );
    shieldPath.quadraticBezierTo(
      size.width * 0.04, size.height * 0.85,
      size.width * 0.04, size.height * 0.58,
    );
    shieldPath.lineTo(size.width * 0.04, size.height * 0.22);
    shieldPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF010D1A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, fillPaint);

    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = neon.withValues(alpha: 0.08 * glowIntensity * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = i * 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(shieldPath, glowPaint);
    }

    final borderPaint = Paint()
      ..color = neon.withValues(alpha: 0.7 + 0.3 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(shieldPath, borderPaint);

    const textStyle = TextStyle(
      color: Color(0xFF00B4FF),
      fontSize: 56,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Color(0xFF00B4FF), blurRadius: 16),
        Shadow(color: Color(0xFF0070CC), blurRadius: 32),
      ],
    );
    final textSpan = TextSpan(text: 'Z', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2 + 4),
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.glowIntensity != glowIntensity;
}

class _CircuitBackground extends StatelessWidget {
  const _CircuitBackground();

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
      ..color = const Color(0xFF0A2040).withValues(alpha: 0.5)
      ..strokeWidth = 0.6;

    final dotPaint = Paint()
      ..color = const Color(0xFF0A3060).withValues(alpha: 0.6)
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
      ..color = const Color(0xFF00B4FF).withValues(alpha: 0.35)
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

class _NeonField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _NeonField({
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
  State<_NeonField> createState() => _NeonFieldState();
}

class _NeonFieldState extends State<_NeonField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? const Color(0xFF00B4FF)
        : const Color(0xFF00B4FF).withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.3),
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
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFF00B4FF).withValues(alpha: 0.4),
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

class _NeonButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _NeonButton({
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
                color: const Color(0xFF00B4FF).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF00B4FF).withValues(alpha: 0.1),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipPath(
            clipper: _BevelClipper(bevel: 10),
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

class _BevelClipper extends CustomClipper<Path> {
  final double bevel;
  _BevelClipper({required this.bevel});

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
  bool shouldReclip(_BevelClipper old) => old.bevel != bevel;
}
