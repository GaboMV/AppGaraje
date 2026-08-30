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
}

final myGaragesProvider =
    AsyncNotifierProvider<MyGaragesNotifier, List<GarageModel>>(
        MyGaragesNotifier.new);
