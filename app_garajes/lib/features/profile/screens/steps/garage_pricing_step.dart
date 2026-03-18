import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/garage_create_provider.dart';

class GaragePricingStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const GaragePricingStep({super.key, required this.onNext});

  @override
  ConsumerState<GaragePricingStep> createState() =>
      _GaragePricingStepState();
}

class _GaragePricingStepState extends ConsumerState<GaragePricingStep> {
  late final TextEditingController _precioCtrl;
  bool _wifi = false;
  bool _bano = false;
  bool _electricidad = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(garageCreateProvider);
    _precioCtrl = TextEditingController(
      text: state.precioDia > 0 ? state.precioDia.toStringAsFixed(0) : '',
    );
    _wifi = state.tieneWifi;
    _bano = state.tieneBano;
    _electricidad = state.tieneElectricidad;
  }

  @override
  void dispose() {
    _precioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final precio = double.tryParse(_precioCtrl.text.trim()) ?? 0;
    if (precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un precio válido'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(garageCreateProvider.notifier).setPricing(
          precioDia: precio,
          wifi: _wifi,
          bano: _bano,
          electricidad: _electricidad,
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
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Establece el precio base y las comodidades disponibles para tu garaje.',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Price box
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
                const Text(
                  'Precio por día',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        border: const Border(
                          top: BorderSide(color: AppTheme.border),
                          left: BorderSide(color: AppTheme.border),
                          bottom: BorderSide(color: AppTheme.border),
                        ),
                      ),
                      child: const Text(
                        '\$',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'))
                        ],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary.withOpacity(0.4),
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            borderSide:
                                BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            borderSide:
                                BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            borderSide:
                                BorderSide(color: AppTheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixText: 'MXN',
                          suffixStyle: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded,
                        size: 12, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Sugerimos un precio entre \$150 - \$400 basado en tu zona.',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Services
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

          const SizedBox(height: 16),
          // Extra service (disabled placeholder)
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Añadir servicio extra cobrado'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: AppTheme.border, style: BorderStyle.solid),
              foregroundColor: AppTheme.textSecondary,
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
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
