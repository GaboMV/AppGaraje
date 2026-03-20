import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/reservation_model.dart';
import '../providers/reservation_provider.dart';

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final isOwner = user?.isPropietario ?? false;

    return DefaultTabController(
      length: isOwner ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Reservas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              const Tab(text: 'Historial'),
              if (isOwner) const Tab(text: 'Solicitudes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _ReservationList(isHistory: true),
            if (isOwner) const _ReservationList(isHistory: false),
          ],
        ),
      ),
    );
  }
}

class _ReservationList extends ConsumerWidget {
  final bool isHistory;
  const _ReservationList({required this.isHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final provider = isHistory ? myReservationsProvider : ownerReservationsProvider;
    final reservationsAsync = ref.watch(provider);

    return reservationsAsync.when(
      data: (list) {
        final filteredList = !isHistory && user != null
            ? list.where((res) => res.idVendedor == user.id).toList()
            : list;

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  isHistory
                      ? 'No has realizado reservas aún'
                      : 'No has recibido solicitudes aún',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _ReservationCard(
            reservation: filteredList[i],
            showActions: !isHistory,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error al cargar reservas'),
            TextButton(
              onPressed: () => ref.refresh(provider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final bool showActions;
  const _ReservationCard({
    required this.reservation,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    switch (reservation.estado.toLowerCase()) {
      case 'pendiente':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'aceptada':
        statusColor = const Color(0xFF10B981);
        break;
      case 'activa':
        statusColor = AppTheme.primary;
        break;
      case 'completada':
        statusColor = AppTheme.textSecondary;
        break;
      case 'rechazada':
      case 'cancelada':
        statusColor = AppTheme.error;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return GestureDetector(
      onTap: () => context.push(
          AppRoutes.reservationById.replaceAll(':id', reservation.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Garage image / Placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: reservation.garageImage != null
                        ? Image.network(reservation.garageImage!, fit: BoxFit.cover)
                        : Container(
                            color: AppTheme.primaryLight,
                            child: const Icon(Icons.garage_rounded,
                                color: AppTheme.primary),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reservation.estado.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            '\$${reservation.totalPrecio.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation.garageName ?? 'Garaje',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 10, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${reservation.fecha} • ${reservation.horaInicio}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
              ],
            ),
            if (showActions && reservation.estado.toLowerCase() == 'pendiente')
              Consumer(builder: (context, ref, _) {
                final user = ref.watch(authProvider).valueOrNull;
                final isVendedor = user?.id == reservation.idVendedor;

                if (!isVendedor) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(reservationProvider.notifier)
                                  .rejectReservation(reservation.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reserva rechazada')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Rechazar',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await ref
                                  .read(reservationProvider.notifier)
                                  .approveReservation(reservation.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reserva aceptada')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Aceptar',
                              style: TextStyle(fontSize: 13, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
