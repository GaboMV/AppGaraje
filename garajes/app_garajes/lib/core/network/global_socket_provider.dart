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
      final name    = data['emisorName'] ?? 'Usuario';
      final content = data['contenido']  ?? 'Nuevo mensaje';
      _showSnackbar('Mensaje de $name: $content', isSuccess: true);
    });

    _socket!.on('pago_exitoso', (data) {
      debugPrint('GlobalSocket: pago_exitoso event received: $data');
      // BUG-05 fix: NO mostrar SnackBar global para pago_exitoso.
      // La pantalla PaymentUploadScreen ya tiene su propio listener local
      // que muestra el SnackBar y hace context.pop().
      // El dueno del garaje recibe su notificacion por el canal 'new_reservation_request'
      // o 'garage_approved' segun el flujo del backend.
      // Mostrar ambos causaria doble SnackBar simultaneo para el comprador.
    });

    _socket!.onDisconnect((_) {
      debugPrint('GlobalSocket: Disconnected');
    });
  }

  /// Permite que pantallas individuales registren un handler para un
  /// evento específico sin tener que acceder al socket directamente.
  /// Retorna una función `off` para limpiar el listener en dispose.
  ///
  /// Uso:
  /// ```dart
  /// late final VoidCallback _offPago;
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _offPago = ref.read(globalSocketProvider)
  ///       .on('pago_exitoso', (data) { ... });
  /// }
  /// @override
  /// void dispose() { _offPago(); super.dispose(); }
  /// ```
  VoidCallback on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
    return () => _socket?.off(event, handler);
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
