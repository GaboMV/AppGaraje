import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/garage_repository.dart';
import '../../home/domain/create_garage_request.dart';
import '../../home/providers/search_provider.dart';

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
  final List<String> imagenesLocales; // local file paths (not yet uploaded)

  // Step 3 — Pricing & Services
  final double precioDia;
  final bool tieneWifi;
  final bool tieneBano;
  final bool tieneElectricidad;

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
    this.precioDia = 0,
    this.tieneWifi = false,
    this.tieneBano = false,
    this.tieneElectricidad = false,
    this.diasHabituales = const {0, 1, 2, 3, 4}, // Lun–Vie default
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
    double? precioDia,
    bool? tieneWifi,
    bool? tieneBano,
    bool? tieneElectricidad,
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
        precioDia: precioDia ?? this.precioDia,
        tieneWifi: tieneWifi ?? this.tieneWifi,
        tieneBano: tieneBano ?? this.tieneBano,
        tieneElectricidad: tieneElectricidad ?? this.tieneElectricidad,
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
  }) {
    state = state.copyWith(
      nombre: nombre,
      descripcion: descripcion,
      imagenesLocales: imagenes,
    );
  }

  void setPricing({
    required double precioDia,
    required bool wifi,
    required bool bano,
    required bool electricidad,
  }) {
    state = state.copyWith(
      precioDia: precioDia,
      tieneWifi: wifi,
      tieneBano: bano,
      tieneElectricidad: electricidad,
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
      final request = CreateGarageRequest(
        nombre: state.nombre,
        direccion: state.direccion,
        lat: state.lat,
        lng: state.lng,
        precioHora: state.precioDia / 24,
        precioDia: state.precioDia,
        capacidad: 1,
        descripcion: state.descripcion.isNotEmpty ? state.descripcion : null,
      );
      await _repo.createGarage(request);
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
