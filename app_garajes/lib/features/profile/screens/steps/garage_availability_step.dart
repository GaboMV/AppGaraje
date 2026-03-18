import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/garage_create_provider.dart';

class GarageAvailabilityStep extends ConsumerStatefulWidget {
  final Future<void> Function() onSubmit;
  const GarageAvailabilityStep({super.key, required this.onSubmit});

  @override
  ConsumerState<GarageAvailabilityStep> createState() =>
      _GarageAvailabilityStepState();
}

class _GarageAvailabilityStepState
    extends ConsumerState<GarageAvailabilityStep> {
  late Set<int> _selectedDays; // 0=Lun … 6=Dom
  late Set<DateTime> _blockedDays;
  late DateTime _displayMonth;

  final List<String> _dayLabels = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(garageCreateProvider);
    _selectedDays = Set.from(state.diasHabituales);
    _blockedDays = Set.from(state.diasBloqueados);
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _toggleDay(int day) =>
      setState(() => _selectedDays.contains(day)
          ? _selectedDays.remove(day)
          : _selectedDays.add(day));

  void _toggleCalendarDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    setState(() => _blockedDays.contains(normalized)
        ? _blockedDays.remove(normalized)
        : _blockedDays.add(normalized));
  }

  bool _isBlocked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _blockedDays.contains(normalized);
  }

  // By default a day is "available" if its weekday maps to a selected day
  // weekday: 1=Mon, 7=Sun → index 0-based = weekday - 1
  bool _isAvailable(DateTime day) {
    final idx = day.weekday - 1; // 0=Mon … 6=Sun
    return _selectedDays.contains(idx) && !_isBlocked(day);
  }

  Future<void> _confirm() async {
    ref.read(garageCreateProvider.notifier).setAvailability(
          diasHabituales: _selectedDays,
          diasBloqueados: _blockedDays,
        );
    await widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(garageCreateProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configura tu horario',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona los días que abrirás habitualmente. Se marcarán automáticamente en el calendario.',
            style: TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Day toggles
          const Text(
            'DÍAS HABITUALES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _selectedDays.contains(i);
              return GestureDetector(
                onTap: () => _toggleDay(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(
                    color: dayColor(selected),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: dayTextColor(selected),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (selected)
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Calendar
          _CalendarWidget(
            displayMonth: _displayMonth,
            isAvailable: _isAvailable,
            isBlocked: _isBlocked,
            onDayTap: _toggleCalendarDay,
            onPrevMonth: () => setState(() => _displayMonth =
                DateTime(_displayMonth.year, _displayMonth.month - 1)),
            onNextMonth: () => setState(() => _displayMonth =
                DateTime(_displayMonth.year, _displayMonth.month + 1)),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              _LegendDot(color: AppTheme.primary, label: 'Disponible'),
              const SizedBox(width: 20),
              _LegendDot(
                  color: AppTheme.border, label: 'No disponible'),
            ],
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: isLoading ? null : _confirm,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(isLoading
                ? 'Publicando...'
                : 'Confirmar Disponibilidad'),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Widget ─────────────────────────────────────────────────────────

class _CalendarWidget extends StatelessWidget {
  final DateTime displayMonth;
  final bool Function(DateTime) isAvailable;
  final bool Function(DateTime) isBlocked;
  final void Function(DateTime) onDayTap;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _CalendarWidget({
    required this.displayMonth,
    required this.isAvailable,
    required this.isBlocked,
    required this.onDayTap,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final monthName = months[displayMonth.month - 1];
    final year = displayMonth.year;

    // Build day grid
    final firstDay =
        DateTime(displayMonth.year, displayMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0=Sunday
    final daysInMonth = DateUtils.getDaysInMonth(year, displayMonth.month);

    final cellCount = startWeekday + daysInMonth;
    final rows = (cellCount / 7).ceil();
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$monthName $year',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: onPrevMonth,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: onNextMonth,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Day headers D M X J V S
        Row(
          children: ['D', 'L', 'M', 'X', 'J', 'V', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Days grid
        for (int row = 0; row < rows; row++)
          Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final day = DateTime(year, displayMonth.month, dayNum);
              final available = isAvailable(day);
              final blocked = isBlocked(day);
              final isPast = day.isBefore(
                  DateTime(today.year, today.month, today.day));

              Color bgColor;
              Color textColor;
              if (isPast) {
                bgColor = Colors.transparent;
                textColor = AppTheme.textSecondary.withOpacity(0.3);
              } else if (blocked) {
                bgColor = AppTheme.border;
                textColor = AppTheme.textSecondary;
              } else if (available) {
                bgColor = AppTheme.primary;
                textColor = Colors.white;
              } else {
                bgColor = Colors.transparent;
                textColor = AppTheme.textPrimary;
              }

              return Expanded(
                child: GestureDetector(
                  onTap:
                      isPast ? null : () => onDayTap(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: available || blocked
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );
}
