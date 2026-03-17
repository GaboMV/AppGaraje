import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

// Auth state notifier
class AuthNotifier extends AsyncNotifier<UserModel?> {
  late final AuthRepository _repo;

  @override
  Future<UserModel?> build() async {
    _repo = ref.read(authRepositoryProvider);
    // Restore session from storage
    final hasToken = await SecureStorageService.hasToken();
    if (!hasToken) return null;

    final info = await SecureStorageService.getUserInfo();
    if (info['id'] == null) return null;

    return UserModel(
      id: info['id']!,
      correo: info['email'] ?? '',
      nombreCompleto: info['name'] ?? '',
      estaVerificado: info['kyc_approved'] == 'true',
    );
  }

  Future<UserModel> register({
    required String nombreCompleto,
    required String correo,
    required String password,
  }) async {
    state = const AsyncLoading();
    final user = await AsyncValue.guard(() => _repo.register(
          nombreCompleto: nombreCompleto,
          correo: correo,
          password: password,
        ));
    state = user;
    return user.value!;
  }

  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    state = const AsyncLoading();
    final user = await AsyncValue.guard(() => _repo.login(
          correo: correo,
          password: password,
        ));
    state = user;
    return user.value!;
  }

  Future<UserModel> loginWithGoogle({required String idToken}) async {
    state = const AsyncLoading();
    final user = await AsyncValue.guard(
        () => _repo.loginWithGoogle(idToken: idToken));
    state = user;
    return user.value!;
  }

  Future<void> refreshProfile() async {
    final result = await AsyncValue.guard(() => _repo.getProfile());
    if (result.hasValue) {
      state = AsyncData(result.value);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// Convenience bool provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
