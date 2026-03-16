import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation_model.dart';

final reservationRepositoryProvider =
    Provider<ReservationRepository>((_) => ReservationRepository());

// Current active reservation for booking flow
final activeReservationProvider =
    StateProvider<ReservationModel?>((_) => null);

class ReservationNotifier
    extends AsyncNotifier<ReservationModel?> {
  late final ReservationRepository _repo;

  @override
  Future<ReservationModel?> build() async {
    _repo = ref.read(reservationRepositoryProvider);
    return null;
  }

  Future<ReservationModel> createReservation({
    required String garageId,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    required String mensaje,
    List<String> serviciosIds = const [],
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repo.createReservation(
          garageId: garageId,
          fecha: fecha,
          horaInicio: horaInicio,
          horaFin: horaFin,
          mensaje: mensaje,
          serviciosIds: serviciosIds,
        ));
    state = result;
    if (result.hasValue) {
      ref.read(activeReservationProvider.notifier).state = result.value;
    }
    return result.value!;
  }

  Future<ReservationModel> payReservation({
    required String reservationId,
    required String metodoPago,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repo.payReservation(
          reservationId: reservationId,
          metodoPago: metodoPago,
        ));
    state = result;
    if (result.hasValue) {
      ref.read(activeReservationProvider.notifier).state = result.value;
    }
    return result.value!;
  }

  Future<void> rateReservation({
    required String reservationId,
    required int calificacion,
    String? comentario,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.rateReservation(
        reservationId: reservationId,
        calificacion: calificacion,
        comentario: comentario,
      );
      return state.value;
    });
  }
}

final reservationProvider =
    AsyncNotifierProvider<ReservationNotifier, ReservationModel?>(
        ReservationNotifier.new);
