import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/neon_widgets.dart';
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
      if (mounted) _showErro(e.toString());
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
          const CircuitBackground(),
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
                      builder: (_, child) =>
                          _ShieldLogo(glowIntensity: _glowAnim.value),
                    ),
                    const SizedBox(height: 20),
                    _buildBrand(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 6),
                    _buildRememberRow(),
                    const SizedBox(height: 24),
                    NeonButton(
                      label: 'ENTRAR',
                      loading: _loading,
                      onTap: _loading ? null : _submit,
                    ),
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
            style: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1),
            children: [
              TextSpan(
                  text: 'Zero', style: TextStyle(color: Colors.white)),
              TextSpan(
                  text: 'Risco',
                  style: TextStyle(color: Color(0xFF00B4FF))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 30,
                height: 1,
                color: const Color(0xFF00B4FF).withOpacity(0.5)),
            const SizedBox(width: 8),
            Text(
              'VIAJE SEGURO. CHEGUE SEGURO.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
                width: 30,
                height: 1,
                color: const Color(0xFF00B4FF).withOpacity(0.5)),
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
          NeonField(
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
          NeonField(
            controller: _passCtrl,
            hint: 'Digite sua senha',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Não tem conta?  ',
          style: TextStyle(
              color: Colors.white.withOpacity(0.55), fontSize: 14),
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

// ── Shield logo animado ──────────────────────────────────────────────────────

class _ShieldLogo extends StatelessWidget {
  final double glowIntensity;
  const _ShieldLogo({required this.glowIntensity});

  @override
  Widget build(BuildContext context) {
    final glow = 0.5 + glowIntensity * 0.5;
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(painter: _ShieldPainter(glowIntensity: glow)),
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

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = const Color(0xFF010D1A)
        ..style = PaintingStyle.fill,
    );

    for (int i = 3; i >= 1; i--) {
      canvas.drawPath(
        shieldPath,
        Paint()
          ..color = neon.withOpacity(0.08 * glowIntensity * i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i * 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = neon.withOpacity(0.7 + 0.3 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    const textStyle = TextStyle(
      color: Color(0xFF00B4FF),
      fontSize: 56,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Color(0xFF00B4FF), blurRadius: 16),
        Shadow(color: Color(0xFF0070CC), blurRadius: 32),
      ],
    );
    final tp = TextPainter(
      text: const TextSpan(text: 'Z', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 + 4));
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.glowIntensity != glowIntensity;
}

// Necessário para que o compilador encontre o símbolo
// ignore: unused_element
final _kDummy = math.pi;
