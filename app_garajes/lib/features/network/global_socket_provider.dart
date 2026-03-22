import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage.dart';

final globalSocketProvider = Provider<GlobalSocketService>((ref) {
  final service = GlobalSocketService();
  
  // Iniciar la conexión en cuanto el provider se lea por primera vez
  service.connect();
  
  ref.onDispose(() {
    service.disconnect();
  });
  
  return service;
});

class GlobalSocketService {
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await SecureStorageService.getToken();
    if (token == null) {
      debugPrint('[GlobalSocket] No token, aborting connection');
      return;
    }

    debugPrint('[GlobalSocket] Iniciando conexión a ${ApiConstants.baseUrl}...');

    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': 'Bearer $token'})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[GlobalSocket] Conectado exitosamente: ${_socket!.id}');
    });

    _socket!.onConnectError((err) {
      debugPrint('[GlobalSocket] Error de conexión: $err');
    });

    _socket!.onError((err) {
      debugPrint('[GlobalSocket] Error general: $err');
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[GlobalSocket] Desconectado: $reason');
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
