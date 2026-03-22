import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                notifier.markAllAsRead();
              },
              child: const Text('Marcar todo como leído'),
            ),
        ],
      ),
      body: state.isLoading && state.notificaciones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notificaciones.isEmpty
              ? const Center(
                  child: Text('No tienes notificaciones por el momento.'),
                )
              : RefreshIndicator(
                  onRefresh: () => notifier.refresh(),
                  child: ListView.builder(
                    itemCount: state.notificaciones.length,
                    itemBuilder: (context, index) {
                      final item = state.notificaciones[index];
                      final isUnread = !item.leido;

                      return ListTile(
                        onTap: () {
                          if (isUnread) {
                            notifier.markAsRead(item.id);
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        tileColor: isUnread
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                        leading: CircleAvatar(
                          backgroundColor:
                              isUnread ? Colors.blue : Colors.grey.shade300,
                          child: Icon(
                            isUnread
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: isUnread ? Colors.white : Colors.black54,
                          ),
                        ),
                        title: Text(
                          item.titulo,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.cuerpo != null && item.cuerpo!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(item.cuerpo!),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(item.fechaCreacion),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Hace un momento';
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
