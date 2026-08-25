import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('GarageSale',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                '¿Qué te trae\npor aquí hoy?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona una opción para empezar tu viaje',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Buscar espacio card
              _ModeCard(
                onTap: () => context.go(AppRoutes.home),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight,
                    AppTheme.primary.withOpacity(0.05)
                  ],
                ),
                icon: Icons.search_rounded,
                iconColor: AppTheme.primary,
                title: 'Quiero buscar un espacio',
                subtitle:
                    'Encuentra el lugar perfecto para vender tus cosas.',
              ),
              const SizedBox(height: 16),

              // Alquilar garaje card
              _ModeCard(
                onTap: () => context.go(AppRoutes.home),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEFF6FF),
                    Colors.blue.withOpacity(0.05)
                  ],
                ),
                icon: Icons.home_work_outlined,
                iconColor: Colors.blue,
                title: 'Quiero alquilar mi garaje',
                subtitle: 'Publica tu espacio libre y gana dinero extra.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ModeCard({
    required this.onTap,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
          color: Colors.white,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with gradient
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(gradient: gradient),
              child: Stack(
                children: [
                  Center(
                    child: Icon(icon,
                        size: 90,
                        color: iconColor.withOpacity(0.15)),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                  ),
                ],
              ),
            ),
            // Text
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
