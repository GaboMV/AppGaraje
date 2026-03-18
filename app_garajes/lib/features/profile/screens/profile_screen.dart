import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary, Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          user?.nombreCompleto.isNotEmpty == true
                              ? user!.nombreCompleto[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.nombreCompleto ?? 'Usuario',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                      Text(
                        user?.correo ?? '',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // KYC status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (user?.estaVerificado ?? false)
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (user?.estaVerificado ?? false)
                              ? Icons.verified_user_rounded
                              : Icons.verified_user_outlined,
                          color: (user?.estaVerificado ?? false)
                              ? AppTheme.secondary
                              : const Color(0xFFF59E0B),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (user?.estaVerificado ?? false)
                                    ? 'Identidad Verificada'
                                    : 'Verificación Pendiente',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: (user?.estaVerificado ?? false)
                                        ? AppTheme.secondary
                                        : const Color(0xFFF59E0B)),
                              ),
                              Text(
                                (user?.estaVerificado ?? false)
                                    ? 'Puedes publicar y alquilar espacios'
                                    : 'Completa tu KYC para publicar garajes',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!(user?.estaVerificado ?? false))
                          TextButton(
                            onPressed: () => context.push(AppRoutes.kyc),
                            child: const Text('Verificar',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  _ProfileOption(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Mi Billetera',
                    subtitle: 'Ver saldo y retiros',
                    onTap: () => context.push(AppRoutes.wallet),
                  ),
                  _ProfileOption(
                    icon: Icons.book_online_outlined,
                    label: 'Mis Reservas',
                    subtitle: 'Historial de reservas',
                    onTap: () {},
                  ),
                  _ProfileOption(
                    icon: Icons.home_work_outlined,
                    label: 'Mis Garajes',
                    subtitle: 'Gestionar espacios publicados',
                    onTap: () => context.push(AppRoutes.myGarages),
                  ),
                  _ProfileOption(
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    onTap: () {},
                  ),
                  _ProfileOption(
                    icon: Icons.help_outline_rounded,
                    label: 'Ayuda y Soporte',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.onboarding);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textSecondary),
        onTap: onTap,
      );
}
