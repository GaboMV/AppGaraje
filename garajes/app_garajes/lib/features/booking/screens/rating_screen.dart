import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/reservation_provider.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String reservationId;
  const RatingScreen({super.key, required this.reservationId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _ownerRating = 0;
  int _spaceRating = 0;
  final _ownerCommentCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _ownerCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ownerRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Califica al propietario antes de continuar'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(reservationProvider.notifier).rateReservation(
            reservationId: widget.reservationId,
            calificacion: _ownerRating,
            comentario: _ownerCommentCtrl.text.trim().isEmpty
                ? null
                : _ownerCommentCtrl.text.trim(),
          );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                      const Expanded(
                        child: Text('CALIFICACIÓN MUTUA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 1,
                                color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('¿Cómo fue tu\nexperiencia?',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Tu opinión ayuda a mejorar la comunidad.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 28),

                      // Rate owner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Califica al Dueño',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Propietario',
                                style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppTheme.primaryLight,
                                  child: const Icon(Icons.person_rounded,
                                      size: 40, color: AppTheme.primary),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Propietario',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            Text('Dueño del espacio',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 16),
                            // Stars
                            _StarRating(
                              value: _ownerRating,
                              onChanged: (r) =>
                                  setState(() => _ownerRating = r),
                              size: 40,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _ownerCommentCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: '¿Algo que destacar?',
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Rate space
                      const Text('Califica el Espacio',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.garage_outlined,
                                  color: AppTheme.primary, size: 36),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('Espacio reservado',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  const SizedBox(height: 6),
                                  _StarRating(
                                    value: _spaceRating,
                                    onChanged: (r) =>
                                        setState(() => _spaceRating = r),
                                    size: 26,
                                    color: AppTheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Submit button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12),
              color: const Color(0xFFF8FAFC).withOpacity(0.9),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Enviar Calificación'),
              ),
            ),
          ),

          // Success overlay
          if (_submitted)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_rounded,
                          color: AppTheme.secondary, size: 60),
                    ),
                    const SizedBox(height: 24),
                    const Text('¡Gracias por tu opinión!',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 26)),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Tu comentario ha sido enviado y ayudará a otros usuarios.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Volver al inicio',
                          style: TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
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

class _StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final Color color;

  const _StarRating({
    required this.value,
    required this.onChanged,
    this.size = 36,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (i) => GestureDetector(
            onTap: () => onChanged(i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < value ? color : AppTheme.border,
                size: size,
              ),
            ),
          ),
        ),
      );
}
