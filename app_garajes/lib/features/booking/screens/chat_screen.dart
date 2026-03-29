import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../network/global_socket_provider.dart';
import '../domain/reservation_model.dart';
import '../providers/reservation_provider.dart';
import '../providers/host_reservations_provider.dart';
import '../../../core/utils/app_logger.dart';

class ChatMessage {
  final String content;
  final String senderId;
  final String senderName;
  final DateTime time;
  final bool isSystem;

  const ChatMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.time,
    this.isSystem = false,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  final String reservationId;
  const ChatScreen({super.key, required this.reservationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  IO.Socket? _socket;
  final List<ChatMessage> _messages = [];
  bool _showPaymentModal = false;
  bool _payLoading = false;
  String _payMethod = 'qr';
  bool _isInitLoaded = false;

  bool _isLoadingRes = true;
  ReservationModel? _reservation;

  @override
  void initState() {
    super.initState();
    AppLogger.info('[ChatScreen] Ciclo de vida initState invocado.');
    debugPrint('[ChatScreen] initState STARTING');
    
    _loadReservation().then((_) => _loadMessages());
    _setupSocketListeners();

    _messages.add(ChatMessage(
      content:
          'Tu comunicación es segura. Por favor mantén el respeto durante la negociación.',
      senderId: 'system',
      senderName: 'Sistema',
      time: DateTime.now(),
      isSystem: true,
    ));
  }

  Future<void> _loadReservation() async {
    try {
      final repo = ref.read(reservationRepositoryProvider);
      final res = await repo.getReservationById(widget.reservationId);
      debugPrint('[ChatScreen] Reserva cargada: ID ${res.id}, Estado: ${res.estado}, Owner: ${res.ownerId}, Renter: ${res.renterId}');
      if (mounted) {
        setState(() {
          _reservation = res;
          _isLoadingRes = false;
        });
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error cargando reserva: $e');
      if (mounted) setState(() => _isLoadingRes = false);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final repo = ref.read(reservationRepositoryProvider);
      final list = await repo.getMessages(widget.reservationId);
      debugPrint('[ChatScreen] ${list.length} mensajes cargados de la base de datos');
      
      if (mounted) {
        setState(() {
          for (var m in list) {
            final senderId = m['emisor']?['id']?.toString() ?? '';
            final senderName = m['emisor']?['nombre_completo'] ?? 'Usuario';
            final content = m['contenido'] ?? '';
            final timeStr = m['fecha_creacion'];
            final time = timeStr != null ? DateTime.tryParse(timeStr) ?? DateTime.now() : DateTime.now();

            _messages.add(ChatMessage(
              content: content,
              senderId: senderId,
              senderName: senderName,
              time: time,
            ));
          }
          _isInitLoaded = true;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[ChatScreen] Error cargando mensajes: $e');
    }
  }

  Future<void> _setupSocketListeners() async {
    final service = ref.read(globalSocketProvider);
    await service.connect();
    
    _socket = service.socket;
    if (_socket == null) {
      debugPrint('[ChatScreen] Error: el Socket Global no está disponible');
      return;
    }

    _socket!.on('joined_room', _onJoinedRoom);
    _socket!.on('receive_message', _onReceiveMessage);
    _socket!.on('reservation_accepted', _onReservationAccepted);

    _joinRoom();
  }

  void _onJoinedRoom(dynamic data) {
    debugPrint('[ChatScreen] Unido al room de reserva: ${data['reservaId']}');
  }

  void _onReceiveMessage(dynamic data) {
    if (!mounted) return;
    debugPrint('[ChatScreen] socket:receive_message -> ${data['contenido']}');
    final senderId = data['emisor']?['id']?.toString() ?? '';
    final senderName = data['emisor']?['nombre_completo'] ?? 'Usuario';
    final content = data['contenido'] ?? '';

    // Avoid double messages if the local state already has it (for the sender)
    final user = ref.read(authProvider).valueOrNull;
    if (senderId == user?.id) {
      debugPrint('[ChatScreen] Mensaje propio recibido por socket, ignorando duplicado local');
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        content: content,
        senderId: senderId,
        senderName: senderName,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _onReservationAccepted(dynamic _) {
    if (!mounted) return;
    debugPrint('[ChatScreen] Evento reservation_accepted recibido');
    _loadReservation(); // Recargar para actualizar estado visual
    setState(() {
      _messages.add(ChatMessage(
        content: 'Sistema: La solicitud ha sido aprobada. Tienes 24h para realizar el pago.',
        senderId: 'system',
        senderName: 'Sistema',
        time: DateTime.now(),
        isSystem: true,
      ));
    });
    _scrollToBottom();
  }

  void _removeSocketListeners() {
    if (_socket == null) return;
    _socket!.off('joined_room', _onJoinedRoom);
    _socket!.off('receive_message', _onReceiveMessage);
    _socket!.off('reservation_accepted', _onReservationAccepted);
    
    _socket!.emit('leave_room', {'reservaId': widget.reservationId});
  }

  void _joinRoom() {
    if (_socket == null) return;
    debugPrint('[ChatScreen] Emitiendo join_room para ${widget.reservationId}');
    _socket!.emit('join_room', {'reservaId': widget.reservationId});
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _socket == null) return;

    final user = ref.read(authProvider).valueOrNull;

    _socket!.emit('send_message', {
      'reservaId': widget.reservationId,
      'contenido': text,
    });

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        senderId: user?.id ?? '',
        senderName: user?.nombreCompleto ?? 'Yo',
        time: DateTime.now(),
      ));
    });
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmPayment() async {
    setState(() => _payLoading = true);
    try {
      await ref.read(reservationProvider.notifier).payReservation(
                reservationId: widget.reservationId,
                metodoPago: _payMethod,
              );
      if (mounted) {
        setState(() => _showPaymentModal = false);
        context.pushReplacement(
            AppRoutes.rating.replaceAll(':reservationId', widget.reservationId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _payLoading = false);
    }
  }

  Future<void> _confirmReservationByHost() async {
    setState(() => _payLoading = true);
    try {
      await ref.read(hostReservationsProvider.notifier).confirmReservation(widget.reservationId);
      if (mounted) {
        _loadReservation(); // Recargar para actualizar UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva confirmada. El inquilino ha sido notificado para pagar.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _payLoading = false);
    }
  }

  @override
  void dispose() {
    _removeSocketListeners();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final myId = user?.id ?? '';
    final ownerId = _reservation?.ownerId ?? '';
    final renterId = _reservation?.renterId ?? '';

    final isPropietarioOfRes = myId == ownerId;
    final isSolicitante = myId == renterId;
    
    debugPrint('[ChatScreen] MyID: $myId, OwnerID: $ownerId, RenterID: $renterId, isOwner: $isPropietarioOfRes, isSolicitante: $isSolicitante');

    final otherName = isPropietarioOfRes ? _reservation?.renterName : _reservation?.ownerName;
    final roleText = isPropietarioOfRes ? 'el Solicitante' : 'el Propietario';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoadingRes 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
        children: [
          Column(
            children: [
              // Chat app bar
              SafeArea(
                bottom: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              isPropietarioOfRes 
                                  ? 'Chat con el solicitante del espacio:' 
                                  : 'Chat con el propietario del espacio:',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            Text(
                              '${_reservation?.garageName ?? 'Espacio'} - ${otherName ?? 'Usuario'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {},
                      ),
                      // Manual Reconnect Button for debugging
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                        onPressed: () {
                          debugPrint('[ChatScreen] Reintento manual de conexión global...');
                          final globalSock = ref.read(globalSocketProvider).socket;
                          if (globalSock != null && !globalSock.connected) {
                            globalSock.connect();
                          }
                          _joinRoom();
                        },
                        tooltip: 'Reconectar Chat', 
                      ),
                    ],
                  ),
                ),
              ),

              // Accepted banner (Client)
              if (!isPropietarioOfRes && _reservation?.isAccepted == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.08),
                    border: Border(
                        bottom: BorderSide(
                            color: AppTheme.secondary.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Solicitud Aceptada',
                                style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text('Tienes 24h para concretar el pago',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _showPaymentModal = true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('REALIZAR PAGO'),
                      ),
                    ],
                  ),
                ),

              // Paid banner (Client and Owner)
              if (_reservation?.isPaid == true || _reservation?.isActive == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    border: Border(
                        bottom: BorderSide(
                            color: const Color(0xFF10B981).withOpacity(0.3))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reserva Confirmada',
                                style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text('El pago se realizó con éxito',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Negotiating Banner (Host)
              if ((_reservation?.isPending == true || _reservation?.isNegotiating == true) && isPropietarioOfRes)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    border: Border(
                        bottom: BorderSide(
                            color: Colors.orange.withOpacity(0.2))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('En Negociación',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text('Confirma si llegaste a un acuerdo.',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _payLoading ? null : _confirmReservationByHost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        child: _payLoading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('CONFIRMAR RESERVA', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    if (msg.isSystem) {
                      return _SystemBubble(msg.content);
                    }
                    final isMe = msg.senderId == myId;
                    return _ChatBubble(msg: msg, isMe: isMe);
                  },
                ),
              ),

              // Input bar
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.of(context).padding.bottom + 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _msgCtrl,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintStyle: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Payment modal
          if (_showPaymentModal) ...[
            GestureDetector(
              onTap: () => setState(() => _showPaymentModal = false),
              child: Container(color: Colors.black54),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _PaymentModal(
                selectedMethod: _payMethod,
                loading: _payLoading,
                onMethodChanged: (m) => setState(() => _payMethod = m),
                onConfirm: _confirmPayment,
                onClose: () => setState(() => _showPaymentModal = false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  const _ChatBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(msg.senderName,
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  final String message;
  const _SystemBubble(this.message);

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message,
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _PaymentModal extends StatelessWidget {
  final String selectedMethod;
  final bool loading;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onConfirm;
  final VoidCallback onClose;

  const _PaymentModal({
    required this.selectedMethod,
    required this.loading,
    required this.onMethodChanged,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Finalizar Reserva',
              style:
                  TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 4),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppTheme.textSecondary),
              children: [
                TextSpan(text: 'Total a pagar: '),
                TextSpan(
                    text: '[Ver en reserva activa]',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR option
          _PayOption(
            value: 'qr',
            selected: selectedMethod == 'qr',
            icon: Icons.qr_code_rounded,
            title: 'Transferencia QR',
            subtitle: 'Recomendado · Instantáneo',
            onTap: () => onMethodChanged('qr'),
          ),
          const SizedBox(height: 10),
          // Card option
          _PayOption(
            value: 'tarjeta',
            selected: selectedMethod == 'tarjeta',
            icon: Icons.credit_card_rounded,
            title: 'Tarjeta de Crédito/Débito',
            subtitle: 'Visa, MC, Amex',
            onTap: () => onMethodChanged('tarjeta'),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: loading ? null : onConfirm,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('CONFIRMAR PAGO'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Transacción 100% Segura',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String value;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PayOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryLight
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppTheme.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppTheme.primary.withOpacity(0.7)
                                : AppTheme.textSecondary)),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: selected ? value : '',
                onChanged: (_) => onTap(),
                activeColor: AppTheme.primary,
              ),
            ],
          ),
        ),
      );
}
