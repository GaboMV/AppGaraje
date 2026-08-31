import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/garage_repository.dart';
import '../../home/domain/garage_model.dart';
import '../../home/providers/search_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

class MyGaragesNotifier extends AsyncNotifier<List<GarageModel>> {
  @override
  Future<List<GarageModel>> build() async {
    try {
      final authState = ref.watch(authProvider);
      final user = authState.valueOrNull;

      if (user == null || user.modoActual != "PROPIETARIO") {
        return [];
      }

      final repo = ref.read(garageRepositoryProvider);
      final list = await repo.getMyGarages();
      return list;
    } catch (e, stack) {
      log('Fallo capturado en MyGaragesProvider', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(garageRepositoryProvider);
      final list = await repo.getMyGarages();
      state = AsyncData(list);
    } catch (e) {
      log('Interrupción observada durante refresh', error: e);
      state = const AsyncData([]);
    }
  }

  Future<void> toggleGarageStatus(String id, bool isAvailable) async {
    try {
      final repo = ref.read(garageRepositoryProvider);
      final updatedGarage = await repo.updateGarage(id, {'disponible': isAvailable});
      state = state.whenData((garages) {
        return garages.map((g) => g.id == id ? updatedGarage : g).toList();
      });
    } catch (e) {
      log('Error toggling garage status', error: e);
      rethrow;
    }
  }

  Future<void> updateGarage(String id, Map<String, dynamic> data) async {
    try {
      final repo = ref.read(garageRepositoryProvider);
      final updatedGarage = await repo.updateGarage(id, data);
      state = state.whenData((garages) {
        return garages.map((g) => g.id == id ? updatedGarage : g).toList();
      });
    } catch (e) {
      log('Error updating garage', error: e);
      rethrow;
    }
  }
}

final myGaragesProvider =
    AsyncNotifierProvider<MyGaragesNotifier, List<GarageModel>>(
        MyGaragesNotifier.new);
