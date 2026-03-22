import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../app.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/providers/my_garages_provider.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../theme/app_theme.dart';

final globalSocketProvider = Provider((ref) {
  final socketService = GlobalSocketService(ref);
  ref.onDispose(() => socketService.dispose());
  return socketService;
});

class GlobalSocketService {
  final ProviderRef ref;
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  GlobalSocketService(this.ref) {
    _initSocket();
  }

  void _initSocket() {
    // Listen to changes in auth state so we automatically connect or disconnect
    ref.listen(authProvider, (previous, next) async {
      final user = next.valueOrNull;
      if (user != null) {
        if (_socket == null || !_socket!.connected) {
          await _connect(user.id);
        }
      } else {
        _disconnect();
      }
    }, fireImmediately: true); // Check state on creation
  }

  Future<void> _connect(String userId) async {
    final token = await SecureStorageService.getToken();
    if (token == null) return;

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('GlobalSocket: Connected as User $userId');
      // Here usually we'd join a global room for the user if the server doesn't do it via Token.
      // E.g., _socket!.emit('join_user_room', {'userId': userId});
    });

    _socket!.on('kyc_approved', (data) {
      debugPrint('GlobalSocket: kyc_approved event received: $data');
      _showSnackbar(data['message'] ?? 'Tu cuenta ha sido verificada!', isSuccess: true);
      // Refresh user profile
      ref.read(authProvider.notifier).refreshProfile();
    });

    _socket!.on('garage_approved', (data) {
      debugPrint('GlobalSocket: garage_approved event received: $data');
      _showSnackbar(data['message'] ?? 'Tu espacio ha sido aprobado!', isSuccess: true);
      // Refresh garages state
      ref.read(myGaragesProvider.notifier).refresh();
      // Also potentially refresh auth for any role changes
      ref.read(authProvider.notifier).refreshProfile();
    });

    _socket!.on('new_reservation_request', (data) {
      debugPrint('GlobalSocket: new_reservation_request event received: $data');
      _showSnackbar(data['message'] ?? '¡Nueva solicitud de reserva!', isSuccess: true);
      // Refresh user profile if needed, or reservations list if that provider existed globally
    });

    _socket!.on('new_message_notification', (data) {
      debugPrint('GlobalSocket: new_message_notification event received: $data');
      final name = data['emisorName'] ?? 'Usuario';
      final content = data['contenido'] ?? 'Nuevo mensaje';
      // Ideally we check if we are not on the chat screen to avoid double alerts, 
      // but SnackBar is decent enough for now.
      _showSnackbar('Mensaje de $name: $content', isSuccess: true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('GlobalSocket: Disconnected');
    });
  }

  void _disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('GlobalSocket: Desconectado deliberadamente (sin sesión o usuario)');
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isSuccess ? AppTheme.secondary : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void dispose() {
    _disconnect();
  }
}
