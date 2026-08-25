import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

// ─── Rating State ─────────────────────────────────────────────────────────────

enum _RatingStatus { idle, loading, success, error }

class _RatingState {
  final _RatingStatus status;
  final String? errorMsg;
  const _RatingState({
    this.status = _RatingStatus.idle,
    this.errorMsg,
  });
  bool get isLoading => status == _RatingStatus.loading;
}

// ─── Rating Notifier ──────────────────────────────────────────────────────────

class _RatingNotifier extends AutoDisposeNotifier<_RatingState> {
  @override
  _RatingState build() => const _RatingState();

  /// Envía la calificación al endpoint:
  ///   POST /api/support/reservas/:idReserva/calificar
  /// Body: { id_objetivo, tipo_objetivo, puntuacion, comentario? }
  Future<bool> submit({
    required String reservaId,
    required String idObjetivo,
    required String tipoObjetivo, // 'USUARIO' | 'GARAJE'
    required int puntuacion,
    String? comentario,
  }) async {
    state = const _RatingState(status: _RatingStatus.loading);
    try {
      await DioClient.instance.post(
        ApiConstants.rate(reservaId),
        data: {
          'id_objetivo': idObjetivo,
          'tipo_objetivo': tipoObjetivo,
          'puntuacion': puntuacion,
          if (comentario != null && comentario.isNotEmpty)
            'comentario': comentario,
        },
      );
      state = const _RatingState(status: _RatingStatus.success);
      return true;
    } on DioException catch (e) {
      final msg = (e.response?.data is Map &&
              e.response!.data['error'] != null)
          ? e.response!.data['error'].toString()
          : e.message ?? 'Error desconocido';
      state = _RatingState(status: _RatingStatus.error, errorMsg: msg);
      return false;
    } catch (_) {
      state = const _RatingState(
        status: _RatingStatus.error,
        errorMsg: 'Error inesperado. Inténtalo de nuevo.',
      );
      return false;
    }
  }
}

final _ratingProvider =
    AutoDisposeNotifierProvider<_RatingNotifier, _RatingState>(
  _RatingNotifier.new,
);

// ─── Public helper ────────────────────────────────────────────────────────────

/// Muestra el [RatingDialog] como `showModalBottomSheet` adaptativo.
///
/// Parámetros:
/// - [reservaId]    : ID de la reserva que se está calificando.
/// - [idObjetivo]   : ID del usuario/garaje que se va a calificar.
/// - [tipoObjetivo] : `'USUARIO'` para calificar a la contraparte,
///                    `'GARAJE'`  para calificar el espacio.
/// - [nombreObjetivo]: Nombre mostrado en el sheet (ej. nombre del propietario).
/// - [onSuccess]    : Callback opcional ejecutado tras envío exitoso.
Future<void> showRatingDialog(
  BuildContext context, {
  required String reservaId,
  required String idObjetivo,
  required String tipoObjetivo,
  String nombreObjetivo = 'la experiencia',
  VoidCallback? onSuccess,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // El bottom sheet hereda el ProviderScope raíz de la app automáticamente.
    // No es necesario (ni correcto) añadir un ProviderScope adicional aquí.
    builder: (_) => _RatingSheet(
      reservaId: reservaId,
      idObjetivo: idObjetivo,
      tipoObjetivo: tipoObjetivo,
      nombreObjetivo: nombreObjetivo,
      onSuccess: onSuccess,
    ),
  );
}

// ─── Bottom Sheet Widget ──────────────────────────────────────────────────────

class _RatingSheet extends ConsumerStatefulWidget {
  final String reservaId;
  final String idObjetivo;
  final String tipoObjetivo;
  final String nombreObjetivo;
  final VoidCallback? onSuccess;

  const _RatingSheet({
    required this.reservaId,
    required this.idObjetivo,
    required this.tipoObjetivo,
    required this.nombreObjetivo,
    this.onSuccess,
  });

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();

  // Label descriptivo de la puntuación para feedback visual inmediato
  static const _labels = ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'];
  static const _labelColors = [
    Colors.transparent,
    AppTheme.error,
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    AppTheme.secondary,
    Color(0xFF059669),
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una estrella para continuar.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Cierra el teclado antes de procesar
    FocusScope.of(context).unfocus();

    final ok = await ref.read(_ratingProvider.notifier).submit(
          reservaId: widget.reservaId,
          idObjetivo: widget.idObjetivo,
          tipoObjetivo: widget.tipoObjetivo,
          puntuacion: _stars,
          comentario: _commentCtrl.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      widget.onSuccess?.call();
      Navigator.of(context).pop(); // Cierra el bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('¡Gracias por tu calificación!'),
            ],
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      final errMsg =
          ref.read(_ratingProvider).errorMsg ?? 'Error al enviar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(_ratingProvider);
    final isLoading = ratingState.isLoading;

    // Padding inferior = teclado cuando está visible
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, keyboardPadding + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cómo fue tu experiencia?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Calificando a ${widget.nombreObjetivo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Close button
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary),
                onPressed:
                    isLoading ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Star Row ─────────────────────────────────────────────────────
          _InteractiveStarRow(
            value: _stars,
            onChanged: isLoading
                ? null
                : (v) => setState(() => _stars = v),
          ),
          const SizedBox(height: 8),

          // ── Puntuación label animado ───────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _stars > 0
                ? Container(
                    key: ValueKey(_stars),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _labelColors[_stars].withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _labels[_stars],
                      style: TextStyle(
                        color: _labelColors[_stars],
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey(0), height: 28),
          ),
          const SizedBox(height: 24),

          // ── Comment TextField ────────────────────────────────────────────
          TextField(
            controller: _commentCtrl,
            enabled: !isLoading,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Deja un comentario (opcional)...',
              hintStyle: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              counterStyle: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Submit ────────────────────────────────────────────────────────
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Enviar Calificación',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Skip ──────────────────────────────────────────────────────────
          const SizedBox(height: 4),
          TextButton(
            onPressed:
                isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Omitir por ahora',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Interactive Star Row ─────────────────────────────────────────────────────

/// Row de 5 estrellas interactivas con soporte para arrastrar (drag-to-rate)
/// y toque puntual. Construido nativamente sin dependencias externas.
class _InteractiveStarRow extends StatefulWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const _InteractiveStarRow({
    required this.value,
    this.onChanged,
  });

  @override
  State<_InteractiveStarRow> createState() => _InteractiveStarRowState();
}

class _InteractiveStarRowState extends State<_InteractiveStarRow> {
  int _hovered = 0; // 0 = sin hover

  int _starFromOffset(double dx, double totalWidth) {
    final starWidth = totalWidth / 5;
    final raw = (dx / starWidth).ceil();
    return raw.clamp(1, 5);
  }

  @override
  Widget build(BuildContext context) {
    final display = _hovered > 0 ? _hovered : widget.value;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final total = constraints.maxWidth;
        return GestureDetector(
          onTapDown: (d) {
            final s = _starFromOffset(d.localPosition.dx, total);
            widget.onChanged?.call(s);
          },
          onHorizontalDragUpdate: (d) {
            final s = _starFromOffset(d.localPosition.dx, total);
            setState(() => _hovered = s);
            widget.onChanged?.call(s);
          },
          onHorizontalDragEnd: (_) => setState(() => _hovered = 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < display;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Icon(
                    key: ValueKey('$i-$filled'),
                    filled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: filled
                        ? const Color(0xFFF59E0B)
                        : AppTheme.border,
                    size: 46,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ─── Public Star Rating Widget (reutilizable en otras pantallas) ──────────────

/// Widget de solo lectura/interactivo de estrellas. Exportado para uso
/// externo en listas, tarjetas de garaje, etc.
class StarRatingWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final Color color;

  const StarRatingWidget({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 32,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(i + 1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < value ? color : AppTheme.border,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
