import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/garage_create_provider.dart';

class GarageDetailsStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const GarageDetailsStep({super.key, required this.onNext});

  @override
  ConsumerState<GarageDetailsStep> createState() =>
      _GarageDetailsStepState();
}

class _GarageDetailsStepState extends ConsumerState<GarageDetailsStep> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(garageCreateProvider);
    _nombreCtrl = TextEditingController(text: state.nombre);
    _descCtrl = TextEditingController(text: state.descripcion);
    _imagePaths = List.from(state.imagenesLocales);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 5 fotos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _imagePaths.add(picked.path));
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  void _save() {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del espacio es requerido'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(garageCreateProvider.notifier).setDetails(
          nombre: nombre,
          descripcion: _descCtrl.text.trim(),
          imagenes: _imagePaths,
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
          // Nombre
          const _Label('Nombre del espacio'),
          const SizedBox(height: 8),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              hintText: 'Ej. Garaje amplio en el centro',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // Descripción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Label('Descripción'),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _descCtrl,
                builder: (_, val, __) => Text(
                  '${val.text.length}/500',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            maxLength: 500,
            buildCounter: (_,
                    {required currentLength,
                    required isFocused,
                    maxLength}) =>
                const SizedBox.shrink(),
            decoration: const InputDecoration(
              hintText:
                  'Describe las características, dimensiones y reglas de tu garaje...',
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Photos
          const _Label('Fotos del lugar'),
          const SizedBox(height: 4),
          Text(
            'Sube al menos 3 fotos para mejores resultados.',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          _ImageGrid(
            paths: _imagePaths,
            onAdd: _pickImage,
            onRemove: _removeImage,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF59E0B), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip pro: Muestra fotos bien iluminadas desde las esquinas para dar una mayor sensación de amplitud.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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

// ─── Image Grid ──────────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ImageGrid({
    required this.paths,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      // Add button
      GestureDetector(
        onTap: onAdd,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: AppTheme.primary,
                width: 1.5,
                style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primary, size: 28),
              SizedBox(height: 4),
              Text('SUBIR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ],
          ),
        ),
      ),
      // Image thumbnails
      ...paths.asMap().entries.map((e) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(e.value),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => onRemove(e.key),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        );
      }),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1,
      children: items,
    );
  }
}

// ─── Label ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15),
      );
}
