import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/reservation_model.dart';
import '../providers/reservation_provider.dart';
import 'widgets/report_issue_dialog.dart';
import 'widgets/rating_dialog.dart';

class ReservationDetailsScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDetailsScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationDetailsProvider(reservationId));

    // Derive reservation for the AppBar action (may still be loading)
    final reservation = reservationAsync.valueOrNull;
    final estado = reservation?.estado.toUpperCase() ?? '';
    final showDisputeBtn =
        estado == 'PAGADA' || estado == 'EN_CURSO';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Reserva',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (showDisputeBtn)
            IconButton(
              tooltip: 'Reportar problema',
              icon: const Icon(Icons.report_problem_outlined),
              color: AppTheme.error,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    ReportIssueDialog(reservationId: reservationId),
              ),
            ),
        ],
      ),
      body: reservationAsync.when(
        data: (reservation) => _ReservationDetailsBody(reservation: reservation),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error al cargar detalle'),
              TextButton(
                onPressed: () => ref.refresh(reservationDetailsProvider(reservationId)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Converted to ConsumerStatefulWidget to manage local _isLoading state for
// the check-in / check-out operations without causing a full provider rebuild.
// ─────────────────────────────────────────────────────────────────────────────
class _ReservationDetailsBody extends ConsumerStatefulWidget {
  final ReservationModel reservation;
  const _ReservationDetailsBody({required this.reservation});

  @override
  ConsumerState<_ReservationDetailsBody> createState() =>
      _ReservationDetailsBodyState();
}

class _ReservationDetailsBodyState
    extends ConsumerState<_ReservationDetailsBody> {
  bool _isLoading = false;

  ReservationModel get reservation => widget.reservation;

  // ── Check-In ────────────────────────────────────────────────────────────
  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reservationProvider.notifier).checkIn(reservation.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Check-in realizado correctamente'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al hacer check-in: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Check-Out ───────────────────────────────────────────────────────────
  Future<void> _handleCheckOut() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reservationProvider.notifier).checkOut(reservation.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Check-out realizado. ¡Gracias!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      // ── Disparar RatingDialog automáticamente tras check-out exitoso ──
      if (mounted) {
        await showRatingDialog(
          context,
          reservaId: reservation.id,
          // El vendedor califica al dueño del espacio (USUARIO)
          idObjetivo: reservation.ownerId,
          tipoObjetivo: 'USUARIO',
          nombreObjetivo: reservation.ownerName ?? 'el propietario del espacio',
          onSuccess: () {
            // Invalida los detalles para reflejar estado COMPLETADA
            ref.invalidate(reservationDetailsProvider(reservation.id));
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al hacer check-out: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Approve / Reject (pre-existing actions) ─────────────────────────────
  Future<void> _handleAction(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      if (type == 'APPROVE') {
        await ref
            .read(reservationProvider.notifier)
            .approveReservation(reservation.id);
        messenger.showSnackBar(
            const SnackBar(content: Text('Reserva aceptada correctamente')));
      } else {
        await ref
            .read(reservationProvider.notifier)
            .rejectReservation(reservation.id);
        messenger
            .showSnackBar(const SnackBar(content: Text('Reserva rechazada')));
      }
      if (mounted) {
        ref.invalidate(reservationDetailsProvider(reservation.id));
      }
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Bottom operation bar builder ─────────────────────────────────────────
  Widget? _buildBottomBar() {
    final user = ref.watch(authProvider).valueOrNull;
    final isVendedor = user?.id == reservation.idVendedor;
    final estado = reservation.estado.toUpperCase();

    // Check-in: only the vendor, only when reservation is PAGADA
    if (isVendedor && estado == 'PAGADA') {
      return _OperationBar(
        icon: Icons.login_rounded,
        label: 'Hacer Check-In',
        color: const Color(0xFF10B981),
        isLoading: _isLoading,
        onTap: _handleCheckIn,
      );
    }

    // Check-out: only the vendor, only when reservation is EN_CURSO
    if (isVendedor && estado == 'EN_CURSO') {
      return _OperationBar(
        icon: Icons.logout_rounded,
        label: 'Hacer Check-Out',
        color: AppTheme.primary,
        isLoading: _isLoading,
        onTap: _handleCheckOut,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final isVendedor = user?.id == reservation.idVendedor;
    final isPending = reservation.estado.toUpperCase() == 'PENDIENTE';

    final bottomBar = _buildBottomBar();

    return Scaffold(
      // Nested Scaffold so the operation bottomNavigationBar doesn't
      // interfere with the outer ReservationDetailsScreen scaffold.
      bottomNavigationBar: bottomBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomBar != null ? 8 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(reservation),
            const SizedBox(height: 20),

            // Garage Info Card
            _buildSectionTitle('Información del Garaje'),
            const SizedBox(height: 12),
            _buildGarageCard(reservation),
            const SizedBox(height: 24),

            // Booking Details
            _buildSectionTitle('Detalles de la Reserva'),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.calendar_today_rounded, 'Fecha', reservation.fecha),
            _buildInfoRow(Icons.access_time_rounded, 'Horario',
                '${reservation.horaInicio} - ${reservation.horaFin}'),
            _buildInfoRow(Icons.payments_outlined, 'Precio Total',
                '\$${reservation.totalPrecio.toStringAsFixed(0)}'),
            if (reservation.mensaje != null &&
                reservation.mensaje!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Mensaje del Cliente'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  reservation.mensaje!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Approve / Reject (owner, PENDIENTE) ──────────────────────
            if (isPending && isVendedor)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => _handleAction('REJECT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Rechazar Solicitud'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => _handleAction('APPROVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Aceptar Reserva',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            else if (bottomBar == null)
              // Show chat button when no operation button applies
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                      AppRoutes.chat
                          .replaceAll(':reservationId', reservation.id)),
                  icon:
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Ir al Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (reservation.estado.toUpperCase() == 'PAGADA' ||
                reservation.estado.toUpperCase() == 'EN_CURSO' ||
                reservation.estado.toUpperCase() == 'COMPLETADA') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showReportModal(context),
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text('Reportar Problema'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: AppTheme.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatusBanner(ReservationModel res) {
    final Color color;
    final String label;
    final IconData icon;

    switch (res.estado.toUpperCase()) {
      case 'PENDIENTE':
        color = const Color(0xFFF59E0B);
        label = 'PENDIENTE DE APROBACIÓN';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'ACEPTADA':
        color = const Color(0xFF10B981);
        label = 'RESERVA ACEPTADA';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'PAGADA':
        color = const Color(0xFF3B82F6);
        label = 'PAGADA – LISTA PARA CHECK-IN';
        icon = Icons.payments_rounded;
        break;
      case 'EN_CURSO':
        color = AppTheme.primary;
        label = 'RESERVA EN CURSO';
        icon = Icons.play_circle_outline_rounded;
        break;
      case 'COMPLETADA':
        color = AppTheme.textSecondary;
        label = 'RESERVA COMPLETADA';
        icon = Icons.event_available_rounded;
        break;
      case 'RECHAZADA':
      case 'CANCELADA':
        color = AppTheme.error;
        label = res.estado.toUpperCase();
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppTheme.textSecondary;
        label = res.estado.toUpperCase();
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageCard(ReservationModel res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: res.garageImage != null
                  ? Image.network(res.garageImage!, fit: BoxFit.cover)
                  : Container(
                      color: AppTheme.primaryLight,
                      child: const Icon(Icons.garage_rounded)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res.garageName ?? 'Garaje',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Text(res.garageAddress ?? 'Sin dirección',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable bottom action bar widget for check-in / check-out operations.
// ─────────────────────────────────────────────────────────────────────────────
class _OperationBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _OperationBar({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Icon(icon, size: 20),
          label: Text(
            isLoading ? 'Procesando...' : label,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _ReportModalContent extends StatefulWidget {
  final String reservationId;

  const _ReportModalContent({required this.reservationId});

  @override
  State<_ReportModalContent> createState() => _ReportModalContentState();
}

class _ReportModalContentState extends State<_ReportModalContent> {
  final _descripcionCtrl = TextEditingController();
  String? _motivoSeleccionado;
  bool _isSubmitting = false;

  final List<String> _motivos = [
    'No me abren el garaje',
    'El espacio es distinto a las fotos',
    'Vehiculo no entra en el espacio',
    'Falla en los servicios (agua, luz, etc.)',
    'Problemas de seguridad',
    'Otro'
  ];

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_motivoSeleccionado == null || _descripcionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un motivo y a?ade una descripciA3n.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = DioClient.instance;
      await dio.post(
        ApiConstants.tickets,
        data: {
          'id_reserva': widget.reservationId,
          'motivo': _motivoSeleccionado,
          'descripcion': _descripcionCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket enviado al administrador'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el ticket: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: AppTheme.error),
              const SizedBox(width: 12),
              const Text(
                'Reportar Problema',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _motivoSeleccionado,
            hint: const Text('Selecciona el motivo',
                style: TextStyle(color: Colors.white70)),
            dropdownColor: const Color(0xFF1E293B),
            items: _motivos.map((String motivo) {
              return DropdownMenuItem<String>(
                value: motivo,
                child: Text(motivo, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: _isSubmitting ? null : (String? newValue) {
              setState(() {
                _motivoSeleccionado = newValue;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descripcionCtrl,
            maxLines: 3,
            enabled: !_isSubmitting,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe el problema con detalle...',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Enviar Reporte',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
