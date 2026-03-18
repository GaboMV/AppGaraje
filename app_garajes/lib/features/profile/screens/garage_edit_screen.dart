import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/garage_model.dart';
import '../providers/my_garages_provider.dart';
import 'package:dio/dio.dart';

class GarageEditScreen extends ConsumerStatefulWidget {
  final GarageModel garage;
  const GarageEditScreen({super.key, required this.garage});

  @override
  ConsumerState<GarageEditScreen> createState() => _GarageEditScreenState();
}

class _GarageEditScreenState extends ConsumerState<GarageEditScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _precioHoraCtrl;
  late final TextEditingController _precioDiaCtrl;
  late final TextEditingController _capacidadCtrl;

  bool _isLoading = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    final g = widget.garage;
    _nombreCtrl = TextEditingController(text: g.nombre);
    _descCtrl = TextEditingController(text: g.descripcion ?? '');
    _direccionCtrl = TextEditingController(text: g.direccion);
    _precioHoraCtrl =
        TextEditingController(text: g.precioPorHora.toStringAsFixed(0));
    _precioDiaCtrl = TextEditingController(
        text: (g.precioPorHora * 24).toStringAsFixed(0));
    _capacidadCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _direccionCtrl.dispose();
    _precioHoraCtrl.dispose();
    _precioDiaCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient.instance;
      await dio.put(
        '${ApiConstants.garages}/${widget.garage.id}',
        data: {
          'nombre': _nombreCtrl.text.trim(),
          'descripcion': _descCtrl.text.trim(),
          'direccion': _direccionCtrl.text.trim(),
          'precio_hora': double.tryParse(_precioHoraCtrl.text) ?? 0,
          'precio_dia': double.tryParse(_precioDiaCtrl.text) ?? 0,
          'capacidad_puestos':
              int.tryParse(_capacidadCtrl.text) ?? 1,
        },
      );
      if (!mounted) return;
      // Refresh the list
      await ref.read(myGaragesProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Garaje actualizado ✓'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data?['error'] ?? 'Error al actualizar'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.garage.imagenes;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editar Garaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image gallery ─────────────────────────────────────────
            if (images.isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.network(
                      images[_currentImageIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primaryLight,
                        child: const Center(
                          child: Icon(Icons.home_work_rounded,
                              color: AppTheme.primary, size: 60),
                        ),
                      ),
                    ),
                  ),
                  // Counter
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${images.length} Fotos',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  // Prev / Next
                  if (_currentImageIndex > 0)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => setState(
                              () => _currentImageIndex--),
                        ),
                      ),
                    ),
                  if (_currentImageIndex < images.length - 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => setState(
                              () => _currentImageIndex++),
                        ),
                      ),
                    ),
                  // Edit gallery button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: OutlinedButton.icon(
                      onPressed: () {}, // future: image upload
                      icon: const Icon(Icons.camera_alt_outlined,
                          size: 16),
                      label: const Text('Editar Galería'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 160,
                color: AppTheme.primaryLight,
                child: const Center(
                  child: Icon(Icons.home_work_rounded,
                      color: AppTheme.primary, size: 60),
                ),
              ),

            // ── Form ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Nombre del Garaje'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Garaje Centro Histórico',
                    ),
                  ),
                  const SizedBox(height: 20),

                  _FieldLabel('Descripción'),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _descCtrl,
                    builder: (_, val, __) {
                      return TextField(
                        controller: _descCtrl,
                        maxLines: 4,
                        maxLength: 500,
                        buildCounter: (_, {required currentLength,
                              required isFocused,
                              maxLength}) =>
                            Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${val.text.length}/500 caracteres',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Describe tu espacio...',
                          alignLabelWithHint: true,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  _FieldLabel('Precio base por día'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          border: Border.all(color: AppTheme.border),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: const Text('\$',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _precioDiaCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: '0',
                            suffixText: 'ARS',
                            suffixStyle: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600),
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
                              borderSide: BorderSide(
                                  color: AppTheme.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const _SectionHeader('Comodidades y Reglas'),
                  const SizedBox(height: 12),

                  _FakeServiceTile(
                      icon: Icons.wifi_rounded,
                      label: 'Wifi disponible',
                      subtitle: 'Para vendedores y clientes',
                      toggled: true),
                  const Divider(height: 1, color: AppTheme.border),
                  _FakeServiceTile(
                      icon: Icons.wc_rounded,
                      label: 'Acceso a Baño',
                      subtitle: '',
                      toggled: false),
                  const Divider(height: 1, color: AppTheme.border),
                  _FakeServiceTile(
                      icon: Icons.security_rounded,
                      label: 'Seguridad 24hs',
                      subtitle: '',
                      toggled: true),
                  const Divider(height: 1, color: AppTheme.border),
                  _FakeServiceTile(
                      icon: Icons.pets_rounded,
                      label: 'Mascotas permitidas',
                      subtitle: '',
                      toggled: false),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Text('Guardar Cambios'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppTheme.textPrimary),
      );
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

class _FakeServiceTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool toggled;

  const _FakeServiceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.toggled,
  });

  @override
  State<_FakeServiceTile> createState() => _FakeServiceTileState();
}

class _FakeServiceTileState extends State<_FakeServiceTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.toggled;
  }

  @override
  Widget build(BuildContext context) => Padding(
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
              child: Icon(widget.icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (widget.subtitle.isNotEmpty)
                    Text(widget.subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: _value,
              onChanged: (v) => setState(() => _value = v),
              activeTrackColor: AppTheme.primary,
            ),
          ],
        ),
      );
}
