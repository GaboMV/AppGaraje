import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

class NotificationsState {
  final List<NotificacionModel> notificaciones;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notificaciones = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificacionModel>? notificaciones,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notificaciones: notificaciones ?? this.notificaciones,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  late final NotificationRepository _repo;

  @override
  NotificationsState build() {
    _repo = ref.read(notificationRepositoryProvider);
    _fetch();
    return const NotificationsState(isLoading: true);
  }

  Future<void> _fetch() async {
    try {
      final data = await _repo.getMyNotifications();
      state = state.copyWith(
        notificaciones: data['notificaciones'],
        unreadCount: data['unreadCount'],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _fetch();
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = state.notificaciones.indexWhere((n) => n.id == id);
    if (index != -1 && !state.notificaciones[index].leido) {
      final newList = List<NotificacionModel>.from(state.notificaciones);
      newList[index] = NotificacionModel(
        id: newList[index].id,
        titulo: newList[index].titulo,
        cuerpo: newList[index].cuerpo,
        leido: true,
        fechaCreacion: newList[index].fechaCreacion,
      );
      state = state.copyWith(
        notificaciones: newList,
        unreadCount: (state.unreadCount > 0) ? state.unreadCount - 1 : 0,
      );
      
      try {
        await _repo.markAsRead(id);
      } catch (e) {
        // Revert on error
        await refresh();
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic
    final newList = state.notificaciones.map((n) => NotificacionModel(
        id: n.id,
        titulo: n.titulo,
        cuerpo: n.cuerpo,
        leido: true,
        fechaCreacion: n.fechaCreacion,
    )).toList();
    
    state = state.copyWith(
      notificaciones: newList,
      unreadCount: 0,
    );
    
    try {
      await _repo.markAllAsRead();
    } catch (e) {
      await refresh();
    }
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
