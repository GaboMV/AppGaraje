import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/garage_create_provider.dart';
import '../../../../core/providers/location_provider.dart';

class GarageLocationStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const GarageLocationStep({super.key, required this.onNext});

  @override
  ConsumerState<GarageLocationStep> createState() =>
      _GarageLocationStepState();
}

class _GarageLocationStepState extends ConsumerState<GarageLocationStep> {
  late final MapController _mapController;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _refCtrl;

  // Center of Mexico City as default
  LatLng _center = const LatLng(19.4326, -99.1332);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final state = ref.read(garageCreateProvider);
    final locState = ref.read(locationProvider);
    
    if (state.lat != 0 && state.lng != 0 && state.lat != 19.4326) {
      _center = LatLng(state.lat, state.lng);
    } else if (locState.position != null) {
      _center = LatLng(locState.position!.latitude, locState.position!.longitude);
    } else {
      _center = LatLng(state.lat != 0 ? state.lat : 19.4326, state.lng != 0 ? state.lng : -99.1332);
    }

    _direccionCtrl = TextEditingController(text: state.direccion);
    _refCtrl = TextEditingController(text: state.referencias);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _direccionCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final dir = _direccionCtrl.text.trim();
    if (dir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa la dirección exacta'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ref.read(garageCreateProvider.notifier).setLocation(
          lat: _center.latitude,
          lng: _center.longitude,
          direccion: dir,
          referencias: _refCtrl.text.trim(),
        );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.position == null && next.position != null) {
        final state = ref.read(garageCreateProvider);
        if (state.lat == 0 || state.lat == 19.4326) {
          final newPos = LatLng(next.position!.latitude, next.position!.longitude);
          setState(() => _center = newPos);
          _mapController.move(newPos, 15.0);
        }
      }
    });

    return Column(
      children: [
        // Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                  onPositionChanged: (pos, _) {
                    setState(() => _center = pos.center);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app_garajes',
                  ),
                ],
              ),
              // Center pin
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Mueve el mapa',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.location_pin,
                        color: AppTheme.primary, size: 48),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
              // Coordinates chip
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    '${_center.latitude.toStringAsFixed(4)}, '
                    '${_center.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom sheet
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección Exacta',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _direccionCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ej. Av. Reforma 222, CDMX',
                        prefixIcon: const Icon(Icons.location_on_outlined,
                            color: AppTheme.primary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Referencias adicionales',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _refCtrl,
                      decoration: const InputDecoration(
                        hintText:
                            'Ej. Portón negro, casa de dos pisos...',
                        suffixIcon: Icon(Icons.notes_rounded,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.primary, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Asegúrate de que el pin esté exactamente en la entrada del garaje para ayudar a los conductores.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Confirmar Ubicación'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
