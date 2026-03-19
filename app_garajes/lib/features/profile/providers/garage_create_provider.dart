import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../../home/data/garage_repository.dart';
import '../../home/domain/create_garage_request.dart';
import '../../home/providers/search_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Wizard State ────────────────────────────────────────────────────────────

class GarageCreateState {
  final int step; // 0-based: 0=Location, 1=Details, 2=Pricing, 3=Availability

  // Step 1 — Location
  final double lat;
  final double lng;
  final String direccion;
  final String referencias;

  // Step 2 — Details
  final String nombre;
  final String descripcion;
  final List<String> imagenesLocales; // fotos publicas
  final String? documentoPropiedadLocal; // foto privada de titulo

  // Step 3 — Pricing & Services
  final double precioHora;
  final double precioDia;
  final bool tieneWifi;
  final bool tieneBano;
  final bool tieneElectricidad;
  final List<Map<String, dynamic>> serviciosExtra; // [{nombre, costo}]

  // Step 4 — Availability
  final Set<int> diasHabituales; // 0=Lun … 6=Dom
  final Set<DateTime> diasBloqueados;

  final bool isLoading;
  final String? error;

  const GarageCreateState({
    this.step = 0,
    this.lat = 19.4326,
    this.lng = -99.1332,
    this.direccion = '',
    this.referencias = '',
    this.nombre = '',
    this.descripcion = '',
    this.imagenesLocales = const [],
    this.documentoPropiedadLocal,
    this.precioHora = 0,
    this.precioDia = 0,
    this.tieneWifi = false,
    this.tieneBano = false,
    this.tieneElectricidad = false,
    this.serviciosExtra = const [],
    this.diasHabituales = const {0, 1, 2, 3, 4},
    this.diasBloqueados = const {},
    this.isLoading = false,
    this.error,
  });

  GarageCreateState copyWith({
    int? step,
    double? lat,
    double? lng,
    String? direccion,
    String? referencias,
    String? nombre,
    String? descripcion,
    List<String>? imagenesLocales,
    String? documentoPropiedadLocal,
    double? precioHora,
    double? precioDia,
    bool? tieneWifi,
    bool? tieneBano,
    bool? tieneElectricidad,
    List<Map<String, dynamic>>? serviciosExtra,
    Set<int>? diasHabituales,
    Set<DateTime>? diasBloqueados,
    bool? isLoading,
    String? error,
  }) =>
      GarageCreateState(
        step: step ?? this.step,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        direccion: direccion ?? this.direccion,
        referencias: referencias ?? this.referencias,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        imagenesLocales: imagenesLocales ?? this.imagenesLocales,
        documentoPropiedadLocal: documentoPropiedadLocal ?? this.documentoPropiedadLocal,
        precioHora: precioHora ?? this.precioHora,
        precioDia: precioDia ?? this.precioDia,
        tieneWifi: tieneWifi ?? this.tieneWifi,
        tieneBano: tieneBano ?? this.tieneBano,
        tieneElectricidad: tieneElectricidad ?? this.tieneElectricidad,
        serviciosExtra: serviciosExtra ?? this.serviciosExtra,
        diasHabituales: diasHabituales ?? this.diasHabituales,
        diasBloqueados: diasBloqueados ?? this.diasBloqueados,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class GarageCreateNotifier extends Notifier<GarageCreateState> {
  late final GarageRepository _repo;

  @override
  GarageCreateState build() {
    _repo = ref.read(garageRepositoryProvider);
    return const GarageCreateState();
  }

  void setLocation({
    required double lat,
    required double lng,
    required String direccion,
    required String referencias,
  }) {
    state = state.copyWith(
      lat: lat,
      lng: lng,
      direccion: direccion,
      referencias: referencias,
    );
  }

  void setDetails({
    required String nombre,
    required String descripcion,
    required List<String> imagenes,
    String? documentoPropiedad,
  }) {
    state = state.copyWith(
      nombre: nombre,
      descripcion: descripcion,
      imagenesLocales: imagenes,
      documentoPropiedadLocal: documentoPropiedad,
    );
  }

  void setPricing({
    required double precioHora,
    required double precioDia,
    required bool wifi,
    required bool bano,
    required bool electricidad,
    required List<Map<String, dynamic>> serviciosExtra,
  }) {
    state = state.copyWith(
      precioHora: precioHora,
      precioDia: precioDia,
      tieneWifi: wifi,
      tieneBano: bano,
      tieneElectricidad: electricidad,
      serviciosExtra: serviciosExtra,
    );
  }

  void setAvailability({
    required Set<int> diasHabituales,
    required Set<DateTime> diasBloqueados,
  }) {
    state = state.copyWith(
      diasHabituales: diasHabituales,
      diasBloqueados: diasBloqueados,
    );
  }

  void goToStep(int step) => state = state.copyWith(step: step);

  void clearError() => state = state.copyWith(error: null);

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (state.documentoPropiedadLocal == null) {
        throw Exception("El documento de propiedad es obligatorio.");
      }

      final mapData = <String, dynamic>{
        'nombre': state.nombre,
        'descripcion': state.descripcion,
        'direccion': state.direccion,
        'latitud': state.lat,
        'longitud': state.lng,
        'precio_hora': state.precioHora,
        'precio_dia': state.precioDia,
        'tiene_wifi': state.tieneWifi,
        'tiene_bano': state.tieneBano,
        'tiene_electricidad': state.tieneElectricidad,
        'tiene_mesa': false,
        // Encode extra services as JSON string (backend can parse)
        if (state.serviciosExtra.isNotEmpty)
          'servicios_extra': state.serviciosExtra
              .map((s) => '${s["nombre"]}:${s["costo"]}')
              .join(','),
      };
      final formData = FormData.fromMap(mapData);

      // Add documento propiedad (private)
      if (state.documentoPropiedadLocal != null) {
        if (kIsWeb) {
          print('Adding private document (Web)');
          final bytes = await XFile(state.documentoPropiedadLocal!).readAsBytes();
          formData.files.add(MapEntry(
            'documento',
            MultipartFile.fromBytes(
              bytes,
              filename: 'documento.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'documento',
            await MultipartFile.fromFile(
              state.documentoPropiedadLocal!,
              filename: 'documento.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        }
      }

      // Add public images
      print('Adding ${state.imagenesLocales.length} public images');
      for (int i = 0; i < state.imagenesLocales.length; i++) {
        final path = state.imagenesLocales[i];
        if (kIsWeb) {
          final bytes = await XFile(path).readAsBytes();
          formData.files.add(MapEntry(
            'imagenes',
            MultipartFile.fromBytes(
              bytes,
              filename: 'img_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        } else {
          formData.files.add(MapEntry(
            'imagenes',
            await MultipartFile.fromFile(
              path,
              filename: 'img_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        }
      }

      await _repo.createGarage(formData);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() => state = const GarageCreateState();
}

final garageCreateProvider =
    NotifierProvider<GarageCreateNotifier, GarageCreateState>(
        GarageCreateNotifier.new);

// Convenience colors (no deps)
Color dayColor(bool selected) =>
    selected ? const Color(0xFF5B4AF7) : const Color(0xFFE5E7EB);

Color dayTextColor(bool selected) =>
    selected ? Colors.white : const Color(0xFF0F0E17);
