import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/neon_widgets.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _role = 'passenger';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _passCtrl.text,
        _role,
      );

      // Notifica admin via Socket.IO quando um motorista se cadastra
      if (_role == 'driver' && mounted) {
        final socket = context.read<SocketService>();
        socket.emit('driver:registered', {'driverName': _nameCtrl.text.trim()});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04090F),
      body: Stack(
        children: [
          const CircuitBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            children: [
                              TextSpan(
                                  text: 'Criar conta\n',
                                  style: TextStyle(color: Colors.white)),
                              TextSpan(
                                  text: 'Zero',
                                  style: TextStyle(color: Colors.white)),
                              TextSpan(
                                  text: 'Risco',
                                  style: TextStyle(color: Color(0xFF00B4FF))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preencha os dados para se cadastrar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildRoleSelector(),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('NOME COMPLETO'),
                              const SizedBox(height: 6),
                              NeonField(
                                controller: _nameCtrl,
                                hint: 'Seu nome completo',
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Informe seu nome'
                                        : null,
                              ),
                              const SizedBox(height: 18),
                              _label('E-MAIL'),
                              const SizedBox(height: 6),
                              NeonField(
                                controller: _emailCtrl,
                                hint: 'seu@email.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Informe o e-mail';
                                  if (!RegExp(r'.+@.+\..+').hasMatch(v)) return 'E-mail inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _label('TELEFONE'),
                              const SizedBox(height: 6),
                              NeonField(
                                controller: _phoneCtrl,
                                hint: '(22) 99999-9999',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Informe o telefone'
                                        : null,
                              ),
                              const SizedBox(height: 18),
                              _label('SENHA'),
                              const SizedBox(height: 6),
                              NeonField(
                                controller: _passCtrl,
                                hint: 'Mínimo 6 caracteres',
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
                        ),
                        const SizedBox(height: 28),
                        NeonButton(
                          label: 'CADASTRAR',
                          loading: _loading,
                          onTap: _loading ? null : _submit,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Já tem conta?  ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Entrar',
                                    style: TextStyle(
                                      color: Color(0xFF00B4FF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF07121E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00B4FF).withOpacity(0.35)),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF00B4FF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      );

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TIPO DE CONTA'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF07121E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00B4FF).withOpacity(0.4)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _roleTab('passenger', Icons.person_rounded, 'Passageiro'),
              _roleTab('driver', Icons.drive_eta_rounded, 'Motorista'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roleTab(String value, IconData icon, String label) {
    final selected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF00B4FF).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: selected
                ? Border.all(color: const Color(0xFF00B4FF).withOpacity(0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? const Color(0xFF00B4FF) : Colors.white.withOpacity(0.35),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF00B4FF) : Colors.white.withOpacity(0.35),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
