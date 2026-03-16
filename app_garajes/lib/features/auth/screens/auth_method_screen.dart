import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AuthMethodScreen extends ConsumerStatefulWidget {
  const AuthMethodScreen({super.key});

  @override
  ConsumerState<AuthMethodScreen> createState() => _AuthMethodScreenState();
}

class _AuthMethodScreenState extends ConsumerState<AuthMethodScreen> {
  bool _googleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('No se obtuvo idToken de Google');

      await ref.read(authProvider.notifier).loginWithGoogle(idToken: idToken);
      if (mounted) context.go(AppRoutes.modeSelection);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hero
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://images.unsplash.com/photo-1531058020387-3be344556be6?auto=format&fit=crop&q=80&w=800',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.primaryLight,
                                child: const Icon(Icons.storefront_outlined,
                                    size: 80, color: AppTheme.primary),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    AppTheme.primary.withOpacity(0.75),
                                    Colors.purple.withOpacity(0.4),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.storefront_rounded,
                                    color: AppTheme.primary, size: 30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Poppins'),
                        children: [
                          TextSpan(text: 'Únete a la '),
                          TextSpan(
                              text: 'comunidad',
                              style: TextStyle(color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Descubre tesoros únicos y encuentra las mejores ventas de garage cerca de ti.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                children: [
                  // Google
                  _SocialButton(
                    onTap: _handleGoogleSignIn,
                    loading: _googleLoading,
                    icon: const Icon(Icons.g_mobiledata_rounded,
                        size: 28, color: Color(0xFF4285F4)),
                    label: 'Continuar con Google',
                    border: true,
                  ),
                  const SizedBox(height: 12),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Email register
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.register),
                    icon: const Icon(Icons.email_outlined, size: 20),
                    label: const Text('Registrarse con Correo'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿Ya tienes cuenta? ',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final Widget icon;
  final String label;
  final bool border;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.loading = false,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border),
          foregroundColor: AppTheme.textPrimary,
          backgroundColor: Colors.white,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
      ),
    );
  }
}
