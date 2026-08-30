import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import 'package:flutter/foundation.dart';

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
    if (!hasToken) {
      debugPrint('[AuthNotifier] AlmacÃ©n local despojado de credenciales asignadas.');
      return null;
    }

    final info = await SecureStorageService.getUserInfo();
    final String? userId = info['id'];
    
    if (userId == null) {
      debugPrint('[AuthNotifier] Inconsistencia en bloque de identidad. Imposible derivar ID usuario.');
      return null;
    }

    debugPrint('[AuthNotifier] Iniciando restauraciÃ³n persistente para ID: $userId');

    return UserModel(
      id: userId,
      correo: info['email'] ?? '',
      nombreCompleto: info['name'] ?? '',
      estaVerificado: info['kyc_approved'] ?? 'NO_VERIFICADO',
      modoActual: info['modo_actual'],
      dniFotoUrl: info['dni_foto_url'],
      selfieUrl: info['selfie_url'],
      urlFotoPerfil: info['url_foto_perfil'], // BUG-03 fix: restaurar avatar
    );
  }

  Future<UserModel> register({
    required String nombreCompleto,
    required String correo,
    required String password,
    String? telefono,
  }) async {
    state = const AsyncLoading();
    final user = await AsyncValue.guard(() => _repo.register(
          nombreCompleto: nombreCompleto,
          correo: correo,
          password: password,
          telefono: telefono,
        ));
    state = user;
    return user.value!;
  }

  Future<UserModel> login({
    required String correo,
    required String password,
  }) async {
    final user = await AsyncValue.guard(() => _repo.login(
          correo: correo,
          password: password,
        ));
    if (user.hasValue) {
      debugPrint('[AuthNotifier] AdquisiciÃ³n de acceso lograda. Referencia jerÃ¡rquica: ${user.value?.modoActual}');
    }
    state = user;
    return user.value!;
  }

  Future<UserModel> loginWithGoogle({String? idToken, String? accessToken}) async {
    state = const AsyncLoading();
    final user = await AsyncValue.guard(() =>
        _repo.loginWithGoogle(idToken: idToken, accessToken: accessToken));
    state = user;
    return user.value!;
  }

  Future<void> refreshProfile() async {
    final result = await AsyncValue.guard(() => _repo.getProfile());
    if (result.hasValue && result.value != null) {
      final user = result.value!;
      await SecureStorageService.saveUserInfo(
        id: user.id,
        name: user.nombreCompleto,
        email: user.correo,
        kycApproved: user.estaVerificado,
        modoActual: user.modoActual,
        dniFotoUrl: user.dniFotoUrl,
        selfieUrl: user.selfieUrl,
        urlFotoPerfil: user.urlFotoPerfil, // BUG-03 fix: persistir avatar
      );
      state = AsyncData(user);
    } else if (result.hasError) {
      // Si el perfil falla por 401, cerramos sesiÃ³n
      final error = result.error as dynamic;
      if (error.toString().contains('401') || error.toString().contains('Unauthorized')) {
        await logout();
      }
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }

  Future<void> verifyEmail(String correo, String token) async {
    await _repo.verifyEmail(correo, token);
  }

  Future<void> forgotPassword(String correo) async {
    await _repo.forgotPassword(correo);
  }

  Future<void> resetPassword({
    required String correo,
    required String token,
    required String newPassword,
  }) async {
    await _repo.resetPassword(
      correo: correo,
      token: token,
      newPassword: newPassword,
    );
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// Convenience bool provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull != null;
});
