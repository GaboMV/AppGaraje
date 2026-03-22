import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reservation_repository.dart';
import '../domain/reservation_model.dart';
import 'reservation_provider.dart';

class HostReservationsNotifier extends AsyncNotifier<List<ReservationModel>> {
  @override
  Future<List<ReservationModel>> build() async {
    return _fetchOwnerReservations();
  }

  Future<List<ReservationModel>> _fetchOwnerReservations() async {
    final repo = ref.read(reservationRepositoryProvider);
    return await repo.getOwnerReservations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOwnerReservations());
  }

  Future<void> acceptForChat(String id) async {
    final repo = ref.read(reservationRepositoryProvider);
    await repo.acceptForChat(id);
    await refresh();
  }

  Future<void> confirmReservation(String id) async {
    final repo = ref.read(reservationRepositoryProvider);
    await repo.confirmReservation(id);
    await refresh();
  }

  Future<void> rejectReservation(String id) async {
    final repo = ref.read(reservationRepositoryProvider);
    await repo.rejectReservation(id);
    await refresh();
  }
}

final hostReservationsProvider =
    AsyncNotifierProvider<HostReservationsNotifier, List<ReservationModel>>(
        HostReservationsNotifier.new);
