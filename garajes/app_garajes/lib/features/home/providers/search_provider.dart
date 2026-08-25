import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/garage_repository.dart';
import '../domain/garage_model.dart';

final garageRepositoryProvider =
    Provider<GarageRepository>((_) => GarageRepository());

// Search filters state
class SearchFilters {
  final String? fecha;
  final String? horaInicio;
  final String? horaFin;
  final String? ubicacion;
  final double? lat;
  final double? lng;
  final double? radius;
  final bool isExplicitLocation; // True when user typed a city, clicked "My Location", or tapped the map.

  const SearchFilters({
    this.fecha,
    this.horaInicio,
    this.horaFin,
    this.ubicacion,
    this.lat,
    this.lng,
    this.radius,
    this.isExplicitLocation = false,
  });

  SearchFilters copyWith({
    String? fecha,
    String? horaInicio,
    String? horaFin,
    String? ubicacion,
    double? lat,
    double? lng,
    double? radius,
    bool? isExplicitLocation,
  }) =>
      SearchFilters(
        fecha: fecha ?? this.fecha,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
        ubicacion: ubicacion ?? this.ubicacion,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        radius: radius ?? this.radius,
        isExplicitLocation: isExplicitLocation ?? this.isExplicitLocation,
      );

  bool get hasFilters =>
      fecha != null ||
      horaInicio != null ||
      horaFin != null ||
      (lat != null && lng != null);
}

// Garage list provider (auto-fetches)
class SearchNotifier extends AsyncNotifier<List<GarageModel>> {
  late final GarageRepository _repo;
  SearchFilters _filters = const SearchFilters();

  @override
  Future<List<GarageModel>> build() async {
    _repo = ref.read(garageRepositoryProvider);
    return _fetchGarages();
  }

  Future<List<GarageModel>> _fetchGarages() {
    return _repo.searchGarages(
      fecha: _filters.fecha,
      horaInicio: _filters.horaInicio,
      horaFin: _filters.horaFin,
      ubicacion: _filters.ubicacion,
      lat: _filters.lat,
      lng: _filters.lng,
      radius: _filters.radius,
    );
  }

  Future<void> applyFilters(SearchFilters filters) async {
    _filters = filters;
    // Update the state provider to keep it in sync with the current search
    ref.read(searchFiltersProvider.notifier).state = filters;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchGarages);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchGarages);
  }
}

final searchProvider =
    AsyncNotifierProvider<SearchNotifier, List<GarageModel>>(SearchNotifier.new);

// Selected garage and its filters
final searchFiltersProvider =
    StateProvider<SearchFilters>((_) => const SearchFilters());

// Selected garage for booking
final selectedGarageProvider = StateProvider<GarageModel?>((_) => null);

// Selected garage services
final selectedServicesProvider =
    StateProvider<List<ServicioModel>>((_) => []);
