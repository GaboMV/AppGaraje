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
  ReservationRepository get _repo => ref.read(reservationRepositoryProvider);

  @override
  Future<ReservationModel?> build() async {
    return null;
  }

  Future<ReservationModel> createReservation({
    required String garageId,
    // DateTime (hora local del usuario) — la conversión a UTC ocurre en el repositorio.
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    required String mensaje,
    required bool aceptaTerminos,
    List<String> serviciosIds = const [],
    List<String> categoriasVenta = const [],
    bool isDiaCompleto = false,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repo.createReservation(
          garageId: garageId,
          fecha: fecha,
          horaInicio: horaInicio,
          horaFin: horaFin,
          mensaje: mensaje,
          aceptaTerminos: aceptaTerminos,
          serviciosIds: serviciosIds,
          categoriasVenta: categoriasVenta,
          tipoCobro: isDiaCompleto ? 'POR_DIA' : 'POR_HORA',
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

  Future<void> approveReservation(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.confirmReservation(id);
      ref.invalidate(ownerReservationsProvider);
      return state.value;
    });
  }

  Future<void> rejectReservation(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.rejectReservation(id);
      ref.invalidate(ownerReservationsProvider);
      ref.invalidate(myReservationsProvider);
      return state.value;
    });
  }

  Future<void> checkIn(String reservationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.checkIn(reservationId);
      ref.invalidate(reservationDetailsProvider(reservationId));
      ref.invalidate(myReservationsProvider);
      return state.value;
    });
  }

  Future<void> checkOut(String reservationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.checkOut(reservationId);
      ref.invalidate(reservationDetailsProvider(reservationId));
      ref.invalidate(myReservationsProvider);
      return state.value;
    });
  }

  /// Submits a dispute for the given reservation.
  /// Uses a plain try/catch (not AsyncValue.guard) so the exception
  /// propagates directly to the calling UI widget, which manages its
  /// own loading state and SnackBar feedback.
  Future<void> submitDispute(String reservationId, String motivo) async {
    try {
      await _repo.reportIssue(reservationId, motivo);
    } catch (e) {
      rethrow;
    }
  }
}

final reservationProvider =
    AsyncNotifierProvider<ReservationNotifier, ReservationModel?>(
        ReservationNotifier.new);

final myReservationsProvider = FutureProvider<List<ReservationModel>>((ref) {
  return ref.watch(reservationRepositoryProvider).getMyReservations();
});

final ownerReservationsProvider = FutureProvider<List<ReservationModel>>((ref) {
  return ref.watch(reservationRepositoryProvider).getOwnerReservations();
});

final reservationDetailsProvider =
    FutureProvider.family<ReservationModel, String>((ref, id) {
  return ref.watch(reservationRepositoryProvider).getReservationById(id);
});

/// Fetches a short-lived Presigned URL for a chat image attachment.
///
/// [autoDispose] ensures the URL is never kept in Riverpod's cache after the
/// widget that watches it is unmounted, preventing stale (expired) URLs from
/// being served on the next render. CachedNetworkImage retains the *downloaded
/// bytes* on disk, so the image remains visible even after the URL expires.
final chatAttachmentUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, key) {
  return ref.read(reservationRepositoryProvider).getChatAttachmentUrl(key);
});
