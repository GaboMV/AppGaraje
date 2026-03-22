import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/garage_model.dart';
import '../providers/search_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../notifications/providers/notifications_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  int _selectedNav = 0;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapChanged(MapCamera camera, bool hasGesture) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      final center = camera.center;
      final bounds = camera.visibleBounds;
      const distance = Distance();
      final radius = distance.as(LengthUnit.Kilometer, center, bounds.northEast);

      ref.read(searchProvider.notifier).applyFilters(
            ref.read(searchFiltersProvider).copyWith(
                  lat: center.latitude,
                  lng: center.longitude,
                  radius: radius,
                ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.position == null && next.position != null) {
        _mapController.move(
          LatLng(next.position!.latitude, next.position!.longitude),
          13.0,
        );
      }
    });

    final locationState = ref.watch(locationProvider);
    final filters = ref.watch(searchFiltersProvider);
    final initialCenter = filters.lat != null && filters.lng != null
        ? LatLng(filters.lat!, filters.lng!)
        : (locationState.position != null
            ? LatLng(locationState.position!.latitude,
                locationState.position!.longitude)
            : const LatLng(-12.0464, -77.0428));

    final authState = ref.watch(authProvider);
    final userName = authState.valueOrNull?.nombreCompleto.split(' ').first ?? 'Usuario';
    final searchAsync = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Header white card
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    // Name & Avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hola, $userName',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                            const Text('Encuentra tu espacio',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary)),
                          ],
                        ),
                        Row(
                          children: [
                            if (authState.valueOrNull?.isPropietario == true)
                              IconButton(
                                icon: const Icon(Icons.dashboard_customize_rounded, color: AppTheme.primary),
                                onPressed: () => context.push(AppRoutes.hostDashboard),
                                tooltip: 'Administrar mis garajes',
                              ),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.notifications),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: const Icon(Icons.notifications_none_rounded,
                                        color: AppTheme.textSecondary, size: 22),
                                  ),
                                  if (ref.watch(notificationsProvider).unreadCount > 0)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${ref.watch(notificationsProvider).unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.profile),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: AppTheme.primary, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search bar
                    GestureDetector(
                      onTap: () => _showLocationSearchDialog(context),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  filters.ubicacion ?? 'Ubicación o ciudad...',
                                  style: TextStyle(
                                      color: filters.ubicacion != null
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      fontWeight: filters.ubicacion != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date filter
                    GestureDetector(
                      onTap: () => _showDatePicker(context),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppTheme.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ref.watch(searchFiltersProvider).fecha ??
                                    'Seleccionar Fechas',
                                style: TextStyle(
                                    color: ref.watch(searchFiltersProvider).fecha != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontSize: 14),
                              ),
                            ),
                            if (ref.watch(searchFiltersProvider).fecha != null)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
                                onPressed: () {
                                  ref.read(searchProvider.notifier).applyFilters(
                                        ref.read(searchFiltersProvider).copyWith(fecha: null),
                                      );
                                },
                              )
                            else
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),

                    // Category pills
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _Pill('Ropa', selected: true),
                          const SizedBox(width: 8),
                          _Pill('Electrónica'),
                          const SizedBox(width: 8),
                          _Pill('Muebles'),
                          const SizedBox(width: 8),
                          _Pill('Juguetes'),
                          const SizedBox(width: 8),
                          _Pill('Libros'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // KYC Pending/Review/Rejected Notification
          if (authState.valueOrNull != null && !authState.valueOrNull!.isVerified)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: authState.valueOrNull!.isRejected 
                      ? const Color(0xFFFEE2E2) 
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: authState.valueOrNull!.isRejected 
                      ? const Color(0xFFFECACA) 
                      : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Icon(
                      authState.valueOrNull!.isRejected
                          ? Icons.gpp_bad_rounded
                          : authState.valueOrNull!.isPending
                              ? Icons.hourglass_empty_rounded
                              : Icons.verified_user_outlined,
                      color: authState.valueOrNull!.isRejected 
                          ? AppTheme.error 
                          : const Color(0xFFF59E0B),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.valueOrNull!.isRejected
                                ? 'Verificación Rechazada'
                                : authState.valueOrNull!.isPending
                                    ? 'Verificación en Revisión'
                                    : 'Verificación Pendiente',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: authState.valueOrNull!.isRejected 
                                    ? AppTheme.error 
                                    : const Color(0xFFB45309)),
                          ),
                          Text(
                            authState.valueOrNull!.isRejected
                                ? 'Tu solicitud fue rechazada. Toca para ver el motivo.'
                                : authState.valueOrNull!.isPending
                                    ? 'Estamos revisando tus documentos.'
                                    : 'Debes completar tu KYC para poder reservar.',
                            style: TextStyle(
                                fontSize: 11, 
                                color: (authState.valueOrNull!.isRejected 
                                    ? AppTheme.error 
                                    : const Color(0xFFB45309)).withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    if (!authState.valueOrNull!.isPending)
                      TextButton(
                        onPressed: () => context.push(AppRoutes.kyc),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: Colors.white.withOpacity(0.5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(authState.valueOrNull!.isRejected ? 'Ver' : 'Verificar',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),

          // Map area
          Expanded(
            child: Stack(
              children: [
                // Flutter Map with OpenStreetMap
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 13,
                    onPositionChanged: (camera, hasGesture) {
                      // Only trigger auto-search on map drag if we haven't set an explicit pin
                      if (!ref.read(searchFiltersProvider).isExplicitLocation && hasGesture) {
                        _onMapChanged(camera, hasGesture);
                      }
                    },
                    onTap: (_, latLng) {
                      final currentFilters = ref.read(searchFiltersProvider);
                      ref.read(searchProvider.notifier).applyFilters(
                            currentFilters.copyWith(
                              lat: latLng.latitude,
                              lng: latLng.longitude,
                              isExplicitLocation: true,
                              radius: currentFilters.radius ?? 5.0, // Default 5km
                            ),
                          );
                      _mapController.move(latLng, 13);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app_garajes',
                    ),
                    searchAsync.whenOrNull(
                      data: (garages) => MarkerLayer(
                        markers: garages
                            .where((g) =>
                                g.latitud != 0 && g.longitud != 0)
                            .map((g) => _buildMarker(context, g))
                            .toList(),
                      ),
                    ) ?? const MarkerLayer(markers: []),
                    // Explicit Search Marker
                    if (filters.isExplicitLocation && filters.lat != null && filters.lng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(filters.lat!, filters.lng!),
                            width: 60,
                            height: 60,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: AppTheme.error, size: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Radius Selector & Clear All (Top of Map)
                if (filters.isExplicitLocation || filters.fecha != null)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (filters.isExplicitLocation)
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10)
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [2.0, 5.0, 10.0, 20.0, 50.0]
                                    .map((r) => GestureDetector(
                                          onTap: () {
                                            ref.read(searchProvider.notifier).applyFilters(
                                                  filters.copyWith(radius: r),
                                                );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: filters.radius == r
                                                  ? AppTheme.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              '${r.toInt()} km',
                                              style: TextStyle(
                                                color: filters.radius == r
                                                    ? Colors.white
                                                    : AppTheme.textPrimary,
                                                fontWeight: filters.radius == r
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          const SizedBox(height: 8),
                          // General Reset Button
                          GestureDetector(
                            onTap: () {
                              ref.read(searchProvider.notifier).applyFilters(
                                    const SearchFilters(),
                                  );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10)
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Limpiar filtros y pin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Map controls
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'myLocationBtn',
                        backgroundColor: Colors.white,
                        onPressed: () async {
                          double? lat;
                          double? lng;
                          
                          try {
                            // Mostrar feedback de carga
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Accediendo a tu ubicación...'), duration: Duration(seconds: 1)),
                            );

                            LocationPermission permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                            }

                            if (permission == LocationPermission.deniedForever) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('El acceso al GPS está bloqueado permanentemente en el navegador. Por favor actívalo en la barra de direcciones.')),
                                );
                              }
                              return;
                            }

                            if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                              // Usamos configuraciones más ligeras para Web
                              final pos = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.low,
                                  timeLimit: Duration(seconds: 5),
                                ),
                              );
                              lat = pos.latitude;
                              lng = pos.longitude;
                            }
                          } catch (e) {
                            debugPrint('Location error: $e');
                            // Si falla getCurrentPosition (timeout), intentamos getLastKnownPosition
                            final lastPos = await Geolocator.getLastKnownPosition();
                            if (lastPos != null) {
                              lat = lastPos.latitude;
                              lng = lastPos.longitude;
                            }
                          }
                          
                          if (lat != null && lng != null) {
                            final latLng = LatLng(lat, lng);
                            ref.read(searchProvider.notifier).applyFilters(
                                  filters.copyWith(
                                    lat: latLng.latitude,
                                    lng: latLng.longitude,
                                    isExplicitLocation: true,
                                    radius: filters.radius ?? 5.0,
                                  ),
                                );
                            _mapController.move(latLng, 14);
                          } else {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No se pudo acceder a tu ubicación. Verifica los permisos de tu navegador.')),
                                );
                             }
                          }
                        },
                        icon: const Icon(Icons.my_location_rounded, color: AppTheme.primary),
                        label: const Text('Mi Ubicación', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: 'viewListBtn',
                        backgroundColor: AppTheme.textPrimary,
                        onPressed: () => context.push(AppRoutes.searchResults),
                        child: const Icon(Icons.list_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom nav
          _BottomNav(
            selected: _selectedNav,
            onSelect: (i) {
              setState(() => _selectedNav = i);
              if (i == 4) context.push(AppRoutes.profile);
              if (i == 3) context.push(AppRoutes.myReservations);
              if (i == 2) context.push(AppRoutes.wallet);
            },
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(BuildContext context, GarageModel g) {
    return Marker(
      point: LatLng(g.latitud, g.longitud),
      width: 70,
      height: 36,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedGarageProvider.notifier).state = g;
          context.push(AppRoutes.garageDetails);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Center(
            child: Text(
              '\$${g.precioPorHora.toStringAsFixed(0)}/h',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      final formatted =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      ref.read(searchProvider.notifier).applyFilters(
          ref.read(searchFiltersProvider).copyWith(fecha: formatted));
    }
  }

  void _showLocationSearchDialog(BuildContext context) {
    final curFilters = ref.read(searchFiltersProvider);
    final ctrl = TextEditingController(text: curFilters.ubicacion);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buscar localidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ej. La Paz, Lima...',
                prefixIcon: const Icon(Icons.location_city_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () => ctrl.clear(),
                ),
              ),
              onSubmitted: (val) async {
                if (val.trim().isEmpty) return;
                
                // Show loading indicator in dialog or handle loading state natively
                try {
                  final dio = Dio();
                  final res = await dio.get('https://nominatim.openstreetmap.org/search', queryParameters: {
                    'q': val,
                    'format': 'json',
                    'limit': 1
                  });
                  
                  if (res.data != null && res.data is List && res.data.isNotEmpty) {
                    final lat = double.parse(res.data[0]['lat'].toString());
                    final lon = double.parse(res.data[0]['lon'].toString());
                    
                    if (mounted) Navigator.pop(ctx);
                    
                    final latLng = LatLng(lat, lon);
                    ref.read(searchProvider.notifier).applyFilters(
                          curFilters.copyWith(
                            lat: latLng.latitude,
                            lng: latLng.longitude,
                            ubicacion: val,
                            isExplicitLocation: true,
                            radius: curFilters.radius ?? 5.0,
                          ),
                        );
                    _mapController.move(latLng, 13);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ubicación no encontrada')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error buscando ubicación')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              icon: const Icon(Icons.close, color: AppTheme.error),
              label: const Text('Limpiar búsqueda', style: TextStyle(color: AppTheme.error)),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(searchProvider.notifier).applyFilters(
                      curFilters.copyWith(
                        ubicacion: null,
                        isExplicitLocation: false,
                        radius: null,
                        lat: null, // Let it reset to user GPS on next refresh or keep map as is
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  const _Pill(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(40),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : [],
        border:
            Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : AppTheme.textSecondary),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _BottomNav({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.explore_rounded, 'Explorar'),
      (Icons.favorite_border_rounded, 'Guardados'),
      (Icons.account_balance_wallet_outlined, 'Billetera'),
      (Icons.chat_bubble_outline_rounded, 'Mensajes'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selected;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1,
                          size: isSelected ? 24 : 22,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary),
                      const SizedBox(height: 2),
                      Text(item.$2,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
