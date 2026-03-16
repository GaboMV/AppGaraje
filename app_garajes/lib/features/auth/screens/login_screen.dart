import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(
            correo: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) context.go(AppRoutes.home);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => context.go(AppRoutes.onboarding),
                  ),
                  const Expanded(
                    child: Text(
                      'Iniciar Sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bienvenido de vuelta',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Inicia sesión para continuar explorando espacios.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 36),
                      _Label('Correo Electrónico'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            hintText: 'tu@correo.com',
                            prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 18),
                      _Label('Contraseña'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: !_showPass,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.authMethod),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: AppTheme.textSecondary),
                              children: [
                                TextSpan(text: '¿No tienes cuenta? '),
                                TextSpan(
                                    text: 'Regístrate',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary)),
      );
}
