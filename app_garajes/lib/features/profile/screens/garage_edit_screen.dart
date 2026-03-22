import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/domain/garage_model.dart';
import '../providers/my_garages_provider.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/data/garage_repository.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http_parser/http_parser.dart';

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

  late final TextEditingController _nuevoServicioNombreCtrl;
  late final TextEditingController _nuevoServicioPrecioCtrl;
  
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;

  bool _isLoading = false;
  bool _isDeleting = false;
  int _currentImageIndex = 0;
  final _repo = GarageRepository();

  late bool _tieneWifi;
  late bool _tieneBano;
  late bool _tieneElectricidad;
  late bool _tieneMesa;

  late GarageModel _garage;

  @override
  void initState() {
    super.initState();
    _garage = widget.garage;
    final g = _garage;
    _nombreCtrl = TextEditingController(text: g.nombre);
    _descCtrl = TextEditingController(text: g.descripcion ?? '');
    _direccionCtrl = TextEditingController(text: g.direccion);
    _precioHoraCtrl =
        TextEditingController(text: g.precioPorHora.toStringAsFixed(0));
    _precioDiaCtrl = TextEditingController(
        text: (g.precioPorHora * 24).toStringAsFixed(0));
    _capacidadCtrl = TextEditingController(text: '1');
    
    _tieneMesa = false;

    // Initialize journey hours
    final startParts = g.horaInicioJornada.split(':');
    _horaInicio = startParts.length == 2 
      ? TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]))
      : const TimeOfDay(hour: 8, minute: 0);
      
    final endParts = g.horaFinJornada.split(':');
    _horaFin = endParts.length == 2
      ? TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]))
      : const TimeOfDay(hour: 20, minute: 0);

    _nuevoServicioNombreCtrl = TextEditingController();
    _nuevoServicioPrecioCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _direccionCtrl.dispose();
    _precioHoraCtrl.dispose();
    _precioDiaCtrl.dispose();
    _capacidadCtrl.dispose();
    _nuevoServicioNombreCtrl.dispose();
    _nuevoServicioPrecioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient.instance;
      await dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.garages}/${_garage.id}',
        data: {
          'nombre': _nombreCtrl.text.trim(),
          'descripcion': _descCtrl.text.trim(),
          'direccion': _direccionCtrl.text.trim(),
          'precio_hora': double.tryParse(_precioHoraCtrl.text) ?? 0,
          'precio_dia': double.tryParse(_precioDiaCtrl.text) ?? 0,
          'capacidad_puestos':
              int.tryParse(_capacidadCtrl.text) ?? 1,
          'tiene_wifi': _tieneWifi,
          'tiene_bano': _tieneBano,
          'tiene_electricidad': _tieneElectricidad,
          'tiene_mesa': _tieneMesa,
          'hora_inicio_jornada': _formatTime(_horaInicio),
          'hora_fin_jornada': _formatTime(_horaFin),
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

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickJourneyTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _horaInicio : _horaFin,
    );
    if (t != null) {
      setState(() {
        if (isStart) _horaInicio = t;
        else _horaFin = t;
      });
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: const Text('¿Estás seguro de que quieres eliminar esta foto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      debugPrint('Deleting image $imageId from garage ${_garage.id}');
      await _repo.deleteGarageImage(_garage.id, imageId);
      if (!mounted) return;

      // Refresh list and local state
      await ref.read(myGaragesProvider.notifier).refresh();
      final garages = ref.read(myGaragesProvider).value ?? [];
      final updated =
          garages.firstWhere((g) => g.id == _garage.id, orElse: () => _garage);

      if (mounted) {
        setState(() {
          _garage = updated;
          if (_currentImageIndex >= _garage.imagenes.length) {
            _currentImageIndex =
                _garage.imagenes.isEmpty ? 0 : _garage.imagenes.length - 1;
          }
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto eliminada ✓')));
      }
    } on DioException catch (e) {
      debugPrint('DioError deleting image: ${e.response?.statusCode} - ${e.response?.data}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error del servidor (${e.response?.statusCode}): ${e.response?.data?['error'] ?? e.message}'),
          backgroundColor: AppTheme.error));
    } catch (e) {
      debugPrint('Error deleting image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addServicio() async {
    final nombre = _nuevoServicioNombreCtrl.text.trim();
    final precioStr = _nuevoServicioPrecioCtrl.text.trim();
    final precio = double.tryParse(precioStr);

    if (nombre.isEmpty || precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un nombre y precio válido (mayor a 0)')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repo.addServicioAdicional(_garage.id, nombre, precio);
      if (!mounted) return;

      _nuevoServicioNombreCtrl.clear();
      _nuevoServicioPrecioCtrl.clear();

      await ref.read(myGaragesProvider.notifier).refresh();
      final garages = ref.read(myGaragesProvider).value ?? [];
      final updated = garages.firstWhere((g) => g.id == _garage.id, orElse: () => _garage);

      if (mounted) {
        setState(() => _garage = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Servicio agregado ✓'), backgroundColor: AppTheme.secondary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteServicio(String idServicio) async {
    setState(() => _isLoading = true);
    try {
      await _repo.deleteServicioAdicional(_garage.id, idServicio);
      if (!mounted) return;

      await ref.read(myGaragesProvider.notifier).refresh();
      final garages = ref.read(myGaragesProvider).value ?? [];
      final updated = garages.firstWhere((g) => g.id == _garage.id, orElse: () => _garage);

      if (mounted) {
        setState(() => _garage = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Servicio eliminado ✓'), backgroundColor: AppTheme.secondary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadNewImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      
      // Intentar deducir el tipo a partir de la extensión para mayor compatibilidad con el backend
      final ext = image.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

      final multipart = MultipartFile.fromBytes(
        bytes,
        filename: image.name,
        contentType: MediaType.parse(mimeType),
      );

      await _repo.uploadImage(_garage.id, multipart);
      if (!mounted) return;

      await ref.read(myGaragesProvider.notifier).refresh();
      final garages = ref.read(myGaragesProvider).value ?? [];
      final updated =
          garages.firstWhere((g) => g.id == _garage.id, orElse: () => _garage);

      if (mounted) {
        setState(() {
          _garage = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Foto subida ✓'),
            backgroundColor: AppTheme.secondary));
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGarage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Garaje'),
        content: const Text('¿Estás seguro de que quieres eliminar este garaje permanentemente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('ELIMINAR TODO'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _repo.deleteGarage(_garage.id);
      if (!mounted) return;
      
      await ref.read(myGaragesProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Garaje eliminado')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _garage.imagenes;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Editar Garaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image gallery ─────────────────────────────────────────
                  RepaintBoundary(
                    child: (images.isNotEmpty)
                        ? _GallerySection(
                            images: images,
                            currentIndex: _currentImageIndex,
                            onIndexChanged: (i) => setState(() => _currentImageIndex = i),
                            onDeleteImage: _deleteImage,
                            onAddImage: _uploadNewImage,
                          )
                        : _EmptyGalleryPlaceholder(onAddImage: _uploadNewImage),
                  ),

                  // ── Form ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Nombre del Garaje'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Ej. Garaje Centro Histórico',
                          ),
                        ),
                        const SizedBox(height: 20),

                        const _FieldLabel('Descripción'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: const InputDecoration(
                            hintText: 'Describe tu espacio...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const _FieldLabel('Precio base por día'),
                        const SizedBox(height: 8),
                        _PriceInput(controller: _precioDiaCtrl),
                        const SizedBox(height: 20),

                        const _FieldLabel('Horario de Jornada Completa'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickJourneyTime(true),
                                icon: const Icon(Icons.access_time, size: 16),
                                label: Text('De: ${_formatTime(_horaInicio)}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickJourneyTime(false),
                                icon: const Icon(Icons.access_time_filled, size: 16),
                                label: Text('A: ${_formatTime(_horaFin)}'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: AppTheme.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        const _SectionHeader('Comodidades y Reglas'),
                        const SizedBox(height: 12),

                        _AmenityTile(
                            icon: Icons.wifi_rounded,
                            label: 'Wifi disponible',
                            subtitle: 'Para vendedores y clientes',
                            value: _tieneWifi,
                            onChanged: (v) => setState(() => _tieneWifi = v)),
                        const Divider(height: 1, color: AppTheme.border),
                        _AmenityTile(
                            icon: Icons.wc_rounded,
                            label: 'Acceso a Baño',
                            subtitle: '',
                            value: _tieneBano,
                            onChanged: (v) => setState(() => _tieneBano = v)),
                        const Divider(height: 1, color: AppTheme.border),
                        _AmenityTile(
                            icon: Icons.flash_on_rounded,
                            label: 'Electricidad',
                            subtitle: '',
                            value: _tieneElectricidad,
                            onChanged: (v) => setState(() => _tieneElectricidad = v)),
                        const Divider(height: 1, color: AppTheme.border),
                        _AmenityTile(
                            icon: Icons.table_restaurant_rounded,
                            label: 'Tiene Mesa/Silla',
                            subtitle: '',
                            value: _tieneMesa,
                            onChanged: (v) => setState(() => _tieneMesa = v)),
                        const SizedBox(height: 28),

                        const _SectionHeader('Servicios Adicionales'),
                        const SizedBox(height: 8),
                        const Text(
                            'Ofrece servicios extra que los clientes pueden añadir por un costo adicional (ej. Techo privado, lavado, etc).',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),

                        if (_garage.servicios.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text('No has configurado servicios adicionales',
                                style: TextStyle(
                                    fontSize: 13, color: AppTheme.textSecondary)),
                          )
                        else
                          ..._garage.servicios.map((s) => ListTile(
                                key: ValueKey('svc_${s.id}'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(s.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text('+\$${s.precio.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.bold)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppTheme.error),
                                  onPressed: () => _deleteServicio(s.id),
                                ),
                              )),

                        _NewServiceInput(
                          nombreCtrl: _nuevoServicioNombreCtrl,
                          precioCtrl: _nuevoServicioPrecioCtrl,
                          onAdd: _addServicio,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.maxFinite,
                          child: ElevatedButton(
                            onPressed: _isLoading || _isDeleting ? null : _save,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Guardar Cambios'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Danger Zone - Delete Garage
                        const Divider(height: 40),
                        const Text(
                          'Zona de Peligro',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.maxFinite,
                          child: OutlinedButton.icon(
                            onPressed:
                                _isDeleting || _isLoading ? null : _deleteGarage,
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.delete_forever_rounded),
                            label: const Text('Eliminar este Garaje'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final List<GarageImageModel> images;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<String> onDeleteImage;
  final VoidCallback onAddImage;

  const _GallerySection({
    required this.images,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onDeleteImage,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Image - No Stack navigation
        SizedBox(
          height: 220,
          width: MediaQuery.of(context).size.width,
          child: CachedNetworkImage(
            key: ValueKey('main_${images[currentIndex].id}'),
            imageUrl: images[currentIndex].url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 220,
              width: MediaQuery.of(context).size.width,
              color: AppTheme.primaryLight,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 220,
              width: MediaQuery.of(context).size.width,
              color: AppTheme.primaryLight,
              child: const Center(
                  child: Icon(Icons.home_work_rounded,
                      color: AppTheme.primary, size: 60)),
            ),
          ),
        ),
        
        // Navigation and Actions Row - STABLE for MouseTracker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: currentIndex > 0 ? () => onIndexChanged(currentIndex - 1) : null,
              ),
              const SizedBox(width: 8),
              Text(
                '${currentIndex + 1}/${images.length}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(width: 8),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: currentIndex < images.length - 1 ? () => onIndexChanged(currentIndex + 1) : null,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => onDeleteImage(images[currentIndex].id),
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                tooltip: 'Eliminar foto',
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onAddImage,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Añadir'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),
        // Thumbnails list - Use SingleChildScrollView + Row for extreme stability on Web
        SizedBox(
          height: 60,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(images.length, (i) {
                final isSelected = i == currentIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onIndexChanged(i),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                isSelected ? AppTheme.primary : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            key: ValueKey('thumb_${images[i].id}'),
                            imageUrl: images[i].url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: AppTheme.primaryLight),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyGalleryPlaceholder extends StatelessWidget {
  final VoidCallback onAddImage;
  const _EmptyGalleryPlaceholder({required this.onAddImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: MediaQuery.of(context).size.width,
      color: AppTheme.primaryLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_work_rounded, color: AppTheme.primary, size: 60),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddImage,
            icon: const Icon(Icons.add_a_photo_rounded),
            label: const Text('Subir primera foto'),
          ),
        ],
      ),
    );
  }
}

class _PriceInput extends StatelessWidget {
  final TextEditingController controller;
  const _PriceInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            border: Border.all(color: AppTheme.border),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: const Text('\$',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewServiceInput extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController precioCtrl;
  final VoidCallback onAdd;
  final bool isLoading;

  const _NewServiceInput({
    required this.nombreCtrl,
    required this.precioCtrl,
    required this.onAdd,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                hintText: 'Ej. Lavado Básico',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(width: 1, height: 24, color: AppTheme.border),
          Expanded(
            flex: 1,
            child: TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Precio',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : onAdd,
            icon: const Icon(Icons.add_circle_rounded,
                color: AppTheme.primary, size: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
  final VoidCallback? onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: onTap == null ? Colors.grey : AppTheme.primary, size: 28),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.primaryLight.withOpacity(0.5),
          padding: const EdgeInsets.all(4),
        ),
      );
}

class _AmenityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AmenityTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

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
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.primary,
            ),
          ],
        ),
      );
}
