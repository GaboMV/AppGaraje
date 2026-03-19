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
  late final TextEditingController _precioHoraCtrl;
  late final TextEditingController _precioDiaCtrl;
  bool _wifi = false;
  bool _bano = false;
  bool _electricidad = false;

  // Extra services
  final List<Map<String, dynamic>> _serviciosExtra = [];
  final _extraNombreCtrl = TextEditingController();
  final _extraCostoCtrl = TextEditingController();

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
    _wifi = state.tieneWifi;
    _bano = state.tieneBano;
    _electricidad = state.tieneElectricidad;
    _serviciosExtra.addAll(state.serviciosExtra);
  }

  @override
  void dispose() {
    _precioHoraCtrl.dispose();
    _precioDiaCtrl.dispose();
    _extraNombreCtrl.dispose();
    _extraCostoCtrl.dispose();
    super.dispose();
  }

  void _addServicio() {
    final nombre = _extraNombreCtrl.text.trim();
    final costo = double.tryParse(_extraCostoCtrl.text.trim()) ?? 0;
    if (nombre.isEmpty || costo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre y un costo válido para el servicio'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _serviciosExtra.add({'nombre': nombre, 'costo': costo});
      _extraNombreCtrl.clear();
      _extraCostoCtrl.clear();
    });
  }

  void _removeServicio(int index) {
    setState(() => _serviciosExtra.removeAt(index));
  }

  void _save() {
    final hora = double.tryParse(_precioHoraCtrl.text.trim()) ?? 0;
    final dia = double.tryParse(_precioDiaCtrl.text.trim()) ?? 0;
    if (hora <= 0 && dia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos un precio (por hora o por día)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(garageCreateProvider.notifier).setPricing(
          precioHora: hora,
          precioDia: dia,
          wifi: _wifi,
          bano: _bano,
          electricidad: _electricidad,
          serviciosExtra: List.from(_serviciosExtra),
        );
    widget.onNext();
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
            'Establece los precios y las comodidades disponibles.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Prices ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Precios',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 16),
                _PriceField(
                  label: 'Precio por hora',
                  hint: '0',
                  suffix: 'Bs/h',
                  controller: _precioHoraCtrl,
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 12),
                _PriceField(
                  label: 'Precio por día',
                  hint: '0',
                  suffix: 'Bs/día',
                  controller: _precioDiaCtrl,
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Puedes activar uno o ambos modos de reserva.',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Amenidades ─────────────────────────────────────────────────────
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _ServiceTile(
                  icon: Icons.wifi_rounded,
                  label: 'Wifi',
                  subtitle: 'Internet de alta velocidad',
                  value: _wifi,
                  onChanged: (v) => setState(() => _wifi = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.border),
                _ServiceTile(
                  icon: Icons.wc_rounded,
                  label: 'Baño',
                  subtitle: 'Acceso a sanitario',
                  value: _bano,
                  onChanged: (v) => setState(() => _bano = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.border),
                _ServiceTile(
                  icon: Icons.electrical_services_rounded,
                  label: 'Electricidad',
                  subtitle: 'Tomas de corriente disponibles',
                  value: _electricidad,
                  onChanged: (v) => setState(() => _electricidad = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Servicios extra cobrados ───────────────────────────────────────
          const Text(
            'SERVICIOS EXTRA (COBRADOS)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega servicios adicionales con costo aparte. Ej: Carpa, toldo, silla, etc.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          // Lista de servicios extra añadidos
          if (_serviciosExtra.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _serviciosExtra.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 16, endIndent: 16, color: AppTheme.border),
                itemBuilder: (_, i) {
                  final s = _serviciosExtra[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_offer_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                    title: Text(s['nombre'].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${s['costo']} Bs',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                fontSize: 14)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeServicio(i),
                          child: const Icon(Icons.remove_circle_outline_rounded,
                              color: AppTheme.error, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Formulario para añadir nuevo servicio extra
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Añadir servicio extra',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _extraNombreCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nombre (ej: Carpa)',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _extraCostoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Costo (Bs)',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixText: 'Bs',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addServicio,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(42, 44),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
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

// ─── Price Field ─────────────────────────────────────────────────────────────

class _PriceField extends StatelessWidget {
  final String label;
  final String hint;
  final String suffix;
  final TextEditingController controller;
  final IconData icon;

  const _PriceField({
    required this.label,
    required this.hint,
    required this.suffix,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Service Tile ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
