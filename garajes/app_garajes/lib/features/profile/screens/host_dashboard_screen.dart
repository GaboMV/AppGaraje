import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/providers/host_reservations_provider.dart';
import '../../booking/domain/reservation_model.dart';
import '../providers/my_garages_provider.dart';
import '../../home/domain/garage_model.dart';

class HostDashboardScreen extends ConsumerStatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  ConsumerState<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends ConsumerState<HostDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Administrar mis garajes',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Garajes'),
            Tab(text: 'Solicitudes'),
            Tab(text: 'Reservaciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GaragesTab(),
          _RequestsTab(),
          _ReservationsTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Mis Garajes ──────────────────────────────────────────────
class _GaragesTab extends ConsumerWidget {
  const _GaragesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garagesAsync = ref.watch(myGaragesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.garageCreate),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: garagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (garages) {
          if (garages.isEmpty) {
            return const Center(child: Text('No tienes garajes registrados.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(myGaragesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: garages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final g = garages[i];
                return _GarageCard(garage: g);
              },
            ),
          );
        },
      ),
    );
  }
}

class _GarageCard extends StatelessWidget {
  final GarageModel garage;
  const _GarageCard({required this.garage});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(garage.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_month, color: AppTheme.primary),
              onPressed: () => context.push(AppRoutes.garageCalendar, extra: garage),
              tooltip: 'Calendario',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              onPressed: () => context.push(AppRoutes.garageEdit, extra: garage),
              tooltip: 'Editar',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Solicitudes (PENDIENTE o EN_NEGOCIACION) ─────────────────
class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(hostReservationsProvider);

    return reservationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (allReservations) {
        final requests = allReservations
            .where((r) => r.isPending || r.isNegotiating)
            .toList();

        if (requests.isEmpty) {
          return const Center(child: Text('No hay solicitudes nuevas.'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(hostReservationsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              return _RequestCard(reservation: r);
            },
          ),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final ReservationModel reservation;
  const _RequestCard({required this.reservation});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _loading = false;

  Future<void> _handleAction() async {
    if (widget.reservation.isPending) {
      setState(() => _loading = true);
      try {
        await ref.read(hostReservationsProvider.notifier).acceptForChat(widget.reservation.id);
        if (mounted) context.push(AppRoutes.chat.replaceAll(':reservationId', widget.reservation.id));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      context.push(AppRoutes.chat.replaceAll(':reservationId', widget.reservation.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.reservation.isPending ? Colors.orange : Colors.blue;
    final statusText = widget.reservation.isPending ? 'NUEVA SOLICITUD' : 'EN NEGOCIACIÓN';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Bs.${widget.reservation.totalPrecio.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Garaje reservado: ${widget.reservation.garageName ?? 'Desconocido'}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Solicitado por: ${widget.reservation.renterName ?? 'Usuario'}', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(
              '${widget.reservation.fecha.split('T').first} (${widget.reservation.horaInicio} - ${widget.reservation.horaFin})',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.maxFinite,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _loading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.reservation.isPending ? 'Aprobar para Chat' : 'Ir al Chat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: Reservaciones Confirmadas (ACEPTADA, PAGADA, etc.) ───────
class _ReservationsTab extends ConsumerWidget {
  const _ReservationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(hostReservationsProvider);

    return reservationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (allReservations) {
        final confirmed = allReservations
            .where((r) => r.isAccepted || r.isPaid || r.isActive || r.isCompleted)
            .toList();

        if (confirmed.isEmpty) {
          return const Center(child: Text('Aún no tienes reservaciones confirmadas.'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(hostReservationsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: confirmed.length,
            itemBuilder: (context, i) {
              final r = confirmed[i];
              return _ReservationCard(reservation: r);
            },
          ),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('${reservation.garageName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Fecha: ${reservation.fecha.split('T').first}\nInquilino: ${reservation.renterName}\nEstado: ${reservation.estado}'),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => context.push(AppRoutes.chat.replaceAll(':reservationId', reservation.id)),
        ),
      ),
    );
  }
}
