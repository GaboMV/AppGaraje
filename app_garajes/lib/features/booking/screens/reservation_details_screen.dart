import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/reservation_model.dart';
import '../providers/reservation_provider.dart';

class ReservationDetailsScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDetailsScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationDetailsProvider(reservationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Reserva',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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

class _ReservationDetailsBody extends ConsumerWidget {
  final ReservationModel reservation;
  const _ReservationDetailsBody({required this.reservation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final isVendedor = user?.id == reservation.idVendedor;
    final isPending = reservation.estado.toLowerCase() == 'pendiente';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
          _buildInfoRow(Icons.calendar_today_rounded, 'Fecha', reservation.fecha),
          _buildInfoRow(Icons.access_time_rounded, 'Horario', 
              '${reservation.horaInicio} - ${reservation.horaFin}'),
          _buildInfoRow(Icons.payments_outlined, 'Precio Total', 
              '\$${reservation.totalPrecio.toStringAsFixed(0)}'),
          if (reservation.mensaje != null && reservation.mensaje!.isNotEmpty) ...[
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

          // Actions
          if (isPending && isVendedor)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, ref, 'REJECT'),
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
                    onPressed: () => _handleAction(context, ref, 'APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Aceptar Reserva', 
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(
                    AppRoutes.chat.replaceAll(':reservationId', reservation.id)),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
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
        ],
      ),
    );
  }

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

    switch (res.estado.toLowerCase()) {
      case 'pendiente':
        color = const Color(0xFFF59E0B);
        label = 'PENDIENTE DE APROBACIÓN';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'aceptada':
        color = const Color(0xFF10B981);
        label = 'RESERVA ACEPTADA';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'activa':
        color = AppTheme.primary;
        label = 'RESERVA EN CURSO';
        icon = Icons.play_circle_outline_rounded;
        break;
      case 'completada':
        color = AppTheme.textSecondary;
        label = 'RESERVA COMPLETADA';
        icon = Icons.event_available_rounded;
        break;
      case 'rechazada':
      case 'cancelada':
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1,
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
                  : Container(color: AppTheme.primaryLight, child: const Icon(Icons.garage_rounded)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res.garageName ?? 'Garaje', 
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(res.garageAddress ?? 'Sin dirección', 
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String type) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (type == 'APPROVE') {
        await ref.read(reservationProvider.notifier).approveReservation(reservation.id);
        messenger.showSnackBar(const SnackBar(content: Text('Reserva aceptada correctamente')));
      } else {
        await ref.read(reservationProvider.notifier).rejectReservation(reservation.id);
        messenger.showSnackBar(const SnackBar(content: Text('Reserva rechazada')));
      }
      if (context.mounted) {
        ref.invalidate(reservationDetailsProvider(reservation.id));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }
}
