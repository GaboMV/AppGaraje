import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/data/garage_repository.dart';
import '../../home/domain/garage_model.dart';
import '../../home/providers/search_provider.dart';

class MyGaragesNotifier extends AsyncNotifier<List<GarageModel>> {
  late final GarageRepository _repo;

  @override
  Future<List<GarageModel>> build() async {
    _repo = ref.read(garageRepositoryProvider);
    return _repo.getMyGarages();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getMyGarages());
  }
}

final myGaragesProvider =
    AsyncNotifierProvider<MyGaragesNotifier, List<GarageModel>>(
        MyGaragesNotifier.new);
