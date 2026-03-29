import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/my_garages_provider.dart';
import '../../../core/utils/app_logger.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final myGaragesState = ref.watch(myGaragesProvider);

    AppLogger.info('ProfileScreen - User ID: ${user?.id}');
    myGaragesState.whenOrNull(data: (list) {
      AppLogger.info('ProfileScreen - Garages found: ${list.length}');
      for (var g in list) {
        AppLogger.info('ProfileScreen - Garage ID: ${g.id}, Aprobado: ${g.estaAprobado}');
      }
    });

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
                        user?.isPropietario == true ? 'Propietario' : 'Vendedor',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13),
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
                      color: (user?.isVerified ?? false)
                          ? const Color(0xFFD1FAE5)
                          : (user?.isRejected ?? false)
                              ? const Color(0xFFFEE2E2)
                              : (user?.isPending ?? false)
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (user?.isVerified ?? false)
                                ? const Color(0xFF10B981)
                                : (user?.isRejected ?? false)
                                    ? AppTheme.error
                                    : (user?.isPending ?? false)
                                        ? const Color(0xFFF59E0B)
                                        : AppTheme.textSecondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            (user?.isVerified ?? false)
                                ? Icons.verified_rounded
                                : (user?.isRejected ?? false)
                                    ? Icons.error_outline_rounded
                                    : (user?.isPending ?? false)
                                        ? Icons.hourglass_top_rounded
                                        : Icons.shield_outlined,
                            color: (user?.isVerified ?? false) ||
                                    (user?.isRejected ?? false) ||
                                    (user?.isPending ?? false)
                                ? Colors.white
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (user?.isVerified ?? false)
                                    ? 'Identidad Verificada'
                                    : (user?.isRejected ?? false)
                                        ? 'Verificación Rechazada'
                                        : (user?.isPending ?? false)
                                            ? 'Verificación en Revisión'
                                            : 'Verifica tu Identidad',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: (user?.isVerified ?? false)
                                        ? const Color(0xFF065F46)
                                        : (user?.isRejected ?? false)
                                            ? AppTheme.error
                                            : (user?.isPending ?? false)
                                                ? const Color(0xFF92400E)
                                                : AppTheme.textSecondary),
                              ),
                              Text(
                                (user?.isVerified ?? false)
                                    ? 'Puedes publicar y alquilar espacios'
                                    : (user?.isRejected ?? false)
                                        ? 'Toca para ver el motivo y re-enviar'
                                        : (user?.isPending ?? false)
                                            ? 'Estamos revisando tus documentos'
                                            : 'Completa tu KYC para publicar garajes',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!(user?.isVerified ?? false))
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppTheme.textSecondary),
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
                    onTap: () => context.push(AppRoutes.myReservations),
                  ),
                  
                  // Multi-pestaña: Mis Garajes / Quiero Alquilar
                  if (user?.isPropietario == true || user?.isCustomer == true)
                     myGaragesState.when(
                      data: (garages) {
                        // REGLA DE ORO: Si es PROPIETARIO, mostramos "Mis Garajes" siempre.
                        if (user?.isPropietario == true) {
                          bool todosPendientes = garages.isNotEmpty && garages.every((g) => g.estaAprobado == false);
                          
                          if (todosPendientes) {
                            return _ProfileOption(
                              icon: Icons.pending_actions_rounded,
                              label: 'Solicitud en atención',
                              subtitle: 'Tu espacio está siendo validado',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tu solicitud está siendo atendida por un administrador.')),
                                );
                              },
                            );
                          } else {
                            return _ProfileOption(
                              icon: Icons.home_work_outlined,
                              label: 'Mis Garajes',
                              subtitle: garages.isEmpty ? 'Cargando tus espacios...' : 'Gestionar ${garages.length} espacios',
                              onTap: () => context.push(AppRoutes.myGarages),
                            );
                          }
                        }

                        // REGLA PARA VENDEDORES (CLIENTES): Mostrar el CTA para registrarse
                        return _ProfileOption(
                          icon: Icons.add_business_rounded,
                          label: 'Quiero alquilar mi espacio',
                          subtitle: 'Publica tu primer garaje aquí',
                          onTap: () {
                            if (user?.isVerified == true) {
                              context.push(AppRoutes.garageCreate);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Debes verificar tu identidad (KYC) primero.')),
                              );
                            }
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, _) => _ProfileOption(
                        icon: Icons.error_outline_rounded,
                        label: 'Mis Garajes',
                        subtitle: 'Error al cargar datos',
                        onTap: () => ref.read(myGaragesProvider.notifier).refresh(),
                      ),
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
