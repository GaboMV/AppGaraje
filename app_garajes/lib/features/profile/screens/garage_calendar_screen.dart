import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/garage_model.dart';

class GarageCalendarScreen extends StatefulWidget {
  final GarageModel garage;
  const GarageCalendarScreen({super.key, required this.garage});

  @override
  State<GarageCalendarScreen> createState() =>
      _GarageCalendarScreenState();
}

class _GarageCalendarScreenState extends State<GarageCalendarScreen> {
  late DateTime _displayMonth;
  DateTime? _selectedDay;

  // Fake upcoming reservations for UI demo
  // In production these would come from /api/reservations/owner
  final List<_FakeReservation> _reservations = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  // Days that have reservations
  bool _hasReservation(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _reservations.any((r) {
      final rDay = DateTime(r.date.year, r.date.month, r.date.day);
      return rDay == normalized;
    });
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  bool _isSelected(DateTime day) =>
      _selectedDay != null &&
      day.year == _selectedDay!.year &&
      day.month == _selectedDay!.month &&
      day.day == _selectedDay!.day;

  List<_FakeReservation> _reservationsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _reservations.where((r) {
      final rDay = DateTime(r.date.year, r.date.month, r.date.day);
      return rDay == normalized;
    }).toList();
  }

  String _monthName(int m) => [
        '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ][m];

  String _dayName(DateTime d) => [
        'Domingo', 'Lunes', 'Martes', 'Miércoles',
        'Jueves', 'Viernes', 'Sábado'
      ][d.weekday % 7];

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay;
    final dayReservations =
        selected != null ? _reservationsForDay(selected) : <_FakeReservation>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Calendario del Garaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _displayMonth = DateTime(now.year, now.month);
                _selectedDay =
                    DateTime(now.year, now.month, now.day);
              });
            },
            child: const Text('Hoy',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Calendar container ─────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Month nav
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setState(() => _displayMonth =
                          DateTime(_displayMonth.year,
                              _displayMonth.month - 1)),
                    ),
                    Text(
                      '${_monthName(_displayMonth.month)} ${_displayMonth.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => setState(() => _displayMonth =
                          DateTime(_displayMonth.year,
                              _displayMonth.month + 1)),
                    ),
                  ],
                ),
                // Header
                Row(
                  children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                // Days grid
                _buildCalendarGrid(),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Selected day panel ─────────────────────────────────────
          if (selected != null)
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            '${_dayName(selected).toUpperCase()}, '
                            '${selected.day} '
                            '${_monthName(selected.month).toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary),
                          ),
                          const Spacer(),
                          if (dayReservations.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Confirmado',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.garage.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (dayReservations.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 48,
                                  color: AppTheme.textSecondary),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin reservas este día',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...dayReservations
                          .map((r) => _ReservationCard(reservation: r)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _displayMonth.year;
    final month = _displayMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // firstDay weekday: Mon=1…Sun=7 → offset for Mon-first grid
    final firstDay = DateTime(year, month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final cellCount = startOffset + daysInMonth;
    final rows = (cellCount / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }
            final day = DateTime(year, month, dayNum);
            final today = _isToday(day);
            final selected = _isSelected(day);
            final hasRes = _hasReservation(day);

            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedDay = day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: today && !selected
                        ? Border.all(
                            color: AppTheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected || today
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      if (hasRes && !selected)
                        Positioned(
                          bottom: 5,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

// ─── Reservation Card ─────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final _FakeReservation reservation;
  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    reservation.clientName[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reservation.clientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        '${reservation.rating} Estrellas (${reservation.reviews} reseñas)',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: reservation.horario,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.person_outline_rounded,
                  label: reservation.proposito,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Ver Detalles'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );
}

// ─── Fake Reservation Model ───────────────────────────────────────────────────

class _FakeReservation {
  final DateTime date;
  final String clientName;
  final double rating;
  final int reviews;
  final String horario;
  final String proposito;

  const _FakeReservation({
    required this.date,
    required this.clientName,
    required this.rating,
    required this.reviews,
    required this.horario,
    required this.proposito,
  });
}
