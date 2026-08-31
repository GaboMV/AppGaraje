import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/garage_create_provider.dart';

class GaragePricingStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const GaragePricingStep({super.key, required this.onNext});

  @override
  ConsumerState<GaragePricingStep> createState() => _GaragePricingStepState();
}

class _GaragePricingStepState extends ConsumerState<GaragePricingStep> {
  late final TextEditingController _precioDiaCtrl;
  late final TextEditingController _precioHoraCtrl;
  
  bool _isHourlyEnabled = false;
  bool _isDailyEnabled = false;
  
  bool _wifi = false;
  bool _bano = false;
  bool _electricidad = false;
  
  List<Map<String, dynamic>> _serviciosExtra = [];
  
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    final state = ref.read(garageCreateProvider);
    
    _precioHoraCtrl = TextEditingController(
      text: state.precioHora > 0 ? state.precioHora.toStringAsFixed(0) : '',
    );
    _precioDiaCtrl = TextEditingController(
      text: state.precioDia > 0 ? state.precioDia.toStringAsFixed(0) : '',
    );
    
    _isHourlyEnabled = state.precioHora > 0;
    _isDailyEnabled = state.precioDia > 0;
    
    _wifi = state.tieneWifi;
    _bano = state.tieneBano;
    _electricidad = state.tieneElectricidad;
    
    _serviciosExtra = List<Map<String, dynamic>>.from(state.serviciosExtra);
    
    if (state.horaInicioJornada.isNotEmpty) {
      final parts = state.horaInicioJornada.split(':');
      if (parts.length == 2) {
        _horaInicio = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    
    if (state.horaFinJornada.isNotEmpty) {
      final parts = state.horaFinJornada.split(':');
      if (parts.length == 2) {
        _horaFin = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    
    // Si ninguno está habilitado por defecto, activamos hora
    if (!_isHourlyEnabled && !_isDailyEnabled) {
      _isHourlyEnabled = true;
    }
  }

  @override
  void dispose() {
    _precioDiaCtrl.dispose();
    _precioHoraCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isHourlyEnabled && !_isDailyEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar al menos una modalidad de cobro.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final precioHora = _isHourlyEnabled ? (double.tryParse(_precioHoraCtrl.text.trim()) ?? 0) : 0.0;
    final precioDia = _isDailyEnabled ? (double.tryParse(_precioDiaCtrl.text.trim()) ?? 0) : 0.0;

    if (_isHourlyEnabled && precioHora <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido por hora.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_isDailyEnabled && precioDia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido por día.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    if (_isDailyEnabled) {
      // Validar que la hora de inicio sea anterior a la de fin
      final inicioMinutes = _horaInicio.hour * 60 + _horaInicio.minute;
      final finMinutes = _horaFin.hour * 60 + _horaFin.minute;
      if (inicioMinutes >= finMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La hora de inicio debe ser menor a la hora de fin.'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }

    final state = ref.read(garageCreateProvider);
    
    final hInicioStr = '${_horaInicio.hour.toString().padLeft(2, '0')}:${_horaInicio.minute.toString().padLeft(2, '0')}';
    final hFinStr = '${_horaFin.hour.toString().padLeft(2, '0')}:${_horaFin.minute.toString().padLeft(2, '0')}';

    ref.read(garageCreateProvider.notifier).setPricing(
          precioHora: precioHora,
          precioDia: precioDia,
          wifi: _wifi,
          bano: _bano,
          electricidad: _electricidad,
          serviciosExtra: _serviciosExtra,
          horaInicio: hInicioStr,
          horaFin: hFinStr,
        );
    widget.onNext();
  }
  
  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _horaInicio : _horaFin,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  Future<void> _showAddServiceDialog() async {
    final nameCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Servicio Extra', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre (Ej. Lavado, Aspirado)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: 'Costo extra',
                prefixText: 'Bs. ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;
              if (name.isNotEmpty && cost > 0) {
                setState(() {
                  _serviciosExtra.add({'nombre': name, 'costo': cost});
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(TextEditingController controller, String label, String suffix) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary.withOpacity(0.4),
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('\$', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixText: suffix,
        suffixStyle: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Define tu oferta',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Establece las modalidades de cobro y los servicios que incluye tu garaje.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // --- Cobro por Hora ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isHourlyEnabled ? AppTheme.primary : AppTheme.border, width: _isHourlyEnabled ? 1.5 : 1.0),
              boxShadow: _isHourlyEnabled ? [
                BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Cobro por Hora', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  subtitle: const Text('Permite alquilar tu espacio por fracciones de hora.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  value: _isHourlyEnabled,
                  onChanged: (val) => setState(() => _isHourlyEnabled = val),
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isHourlyEnabled) ...[
                  const SizedBox(height: 12),
                  const Text('Precio por hora', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  _buildPriceInput(_precioHoraCtrl, 'Precio por hora', 'Bs./h'),
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // --- Cobro por Jornada ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isDailyEnabled ? AppTheme.primary : AppTheme.border, width: _isDailyEnabled ? 1.5 : 1.0),
              boxShadow: _isDailyEnabled ? [
                BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Cobro por Jornada (Día)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  subtitle: const Text('Establece un precio fijo para todo el día y su horario.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  value: _isDailyEnabled,
                  onChanged: (val) => setState(() => _isDailyEnabled = val),
                  activeColor: AppTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_isDailyEnabled) ...[
                  const SizedBox(height: 12),
                  const Text('Precio por jornada completa', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  _buildPriceInput(_precioDiaCtrl, 'Precio por jornada', 'Bs./día'),
                  
                  const SizedBox(height: 20),
                  const Text('Horario de la jornada', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hora Inicio', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Text(_horaInicio.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hora Fin', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Text(_horaFin.format(context), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 28),

          // --- Servicios Incluidos ---
          const Text(
            'SERVICIOS INCLUIDOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _ServiceTile(
            icon: Icons.wifi_rounded,
            label: 'Wifi',
            subtitle: 'Internet de alta velocidad',
            value: _wifi,
            onChanged: (v) => setState(() => _wifi = v),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _ServiceTile(
            icon: Icons.wc_rounded,
            label: 'Baño',
            subtitle: 'Acceso a sanitario',
            value: _bano,
            onChanged: (v) => setState(() => _bano = v),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _ServiceTile(
            icon: Icons.electrical_services_rounded,
            label: 'Electricidad',
            subtitle: 'Tomas de corriente disponibles',
            value: _electricidad,
            onChanged: (v) => setState(() => _electricidad = v),
          ),

          const SizedBox(height: 28),
          
          // --- Servicios Extra Cobrados ---
          const Text(
            'SERVICIOS EXTRA (COBRADOS)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (_serviciosExtra.isEmpty)
            const Text('No has añadido servicios extra.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
          else
            ..._serviciosExtra.asMap().entries.map((e) {
              final idx = e.key;
              final serv = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(serv['nombre'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('+ Bs. ${serv['costo']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error),
                    onPressed: () => setState(() => _serviciosExtra.removeAt(idx)),
                  ),
                ),
              );
            }).toList(),
            
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showAddServiceDialog,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Añadir servicio extra'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary, style: BorderStyle.solid),
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 36),

          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Guardar y Continuar'),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
