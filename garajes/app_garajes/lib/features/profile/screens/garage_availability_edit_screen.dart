import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/garage_model.dart';
import '../providers/my_garages_provider.dart';

class GarageAvailabilityEditScreen extends ConsumerStatefulWidget {
  final GarageModel garage;
  const GarageAvailabilityEditScreen({super.key, required this.garage});

  @override
  ConsumerState<GarageAvailabilityEditScreen> createState() =>
      _GarageAvailabilityEditScreenState();
}

class _GarageAvailabilityEditScreenState
    extends ConsumerState<GarageAvailabilityEditScreen> {
  late Set<int> _selectedDays;
  late Set<DateTime> _blockedDays;
  late DateTime _displayMonth;
  bool _isLoading = false;

  final List<String> _dayLabels = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = Set.from(widget.garage.diasHabituales);
    _blockedDays = Set.from(widget.garage.diasBloqueados);
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

  bool _isAvailable(DateTime day) {
    final idx = day.weekday - 1;
    return _selectedDays.contains(idx) && !_isBlocked(day);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final habitualesStr = _selectedDays.join(',');
      final bloqueadosStr = _blockedDays.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').join(',');

      // We'll assume the API wants these directly mapped
      final mapData = <String, dynamic>{
        'dias_habituales': habitualesStr,
        'dias_bloqueados': bloqueadosStr,
      };

      await ref.read(myGaragesProvider.notifier).updateGarage(widget.garage.id, mapData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario actualizado con éxito.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar disponibilidad: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color dayColor(bool selected) =>
      selected ? AppTheme.primary : AppTheme.background;
  Color dayTextColor(bool selected) =>
      selected ? Colors.white : AppTheme.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editar Disponibilidad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configura tu horario',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecciona los días que abrirás habitualmente. Selecciona fechas en el calendario para bloquear excepciones.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

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
                      border: Border.all(color: selected ? Colors.transparent : AppTheme.border),
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
                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            _CalendarWidget(
              displayMonth: _displayMonth,
              isAvailable: _isAvailable,
              isBlocked: _isBlocked,
              onDayTap: _toggleCalendarDay,
              onPrevMonth: () => setState(() =>
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1)),
              onNextMonth: () => setState(() =>
                  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1)),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _LegendDot(color: AppTheme.primary, label: 'Disponible'),
                const SizedBox(width: 20),
                _LegendDot(color: AppTheme.border, label: 'No disponible'),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Disponibilidad'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final startWeekday = firstDay.weekday % 7; 
    final daysInMonth = DateUtils.getDaysInMonth(year, displayMonth.month);

    final cellCount = startWeekday + daysInMonth;
    final rows = (cellCount / 7).ceil();
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$monthName $year',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
              final isPast = day.isBefore(DateTime(today.year, today.month, today.day));

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
                  onTap: isPast ? null : () => onDayTap(day),
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
                          fontWeight: available || blocked ? FontWeight.w700 : FontWeight.w400,
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );
}
