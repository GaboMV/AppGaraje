import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reservation_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Dialog for reporting a dispute on a reservation.
///
/// Uses a local [_isLoading] flag so the global [reservationProvider]
/// state is not polluted during the network call. Errors are shown
/// via a SnackBar and the dialog stays open; on success the dialog
/// closes itself and shows a green SnackBar.
class ReportIssueDialog extends ConsumerStatefulWidget {
  final String reservationId;

  const ReportIssueDialog({super.key, required this.reservationId});

  @override
  ConsumerState<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends ConsumerState<ReportIssueDialog> {
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final motivo = _motivoController.text.trim();

    // Validation
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe el problema antes de enviar.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(reservationProvider.notifier)
          .submitDispute(widget.reservationId, motivo);

      if (!mounted) return;

      // Success: close dialog first, then show SnackBar
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disputa reportada. El administrador la revisara.'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reportar: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.report_problem_rounded, color: AppTheme.error, size: 22),
          const SizedBox(width: 10),
          Text(
            'Reportar Problema',
            style: TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe el problema al administrador. '
            'Se abrira una disputa sobre esta reserva.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _motivoController,
            enabled: !_isLoading,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe el problema al administrador...',
              hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.error, width: 1.5),
              ),
              counterStyle:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.error.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Enviar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
