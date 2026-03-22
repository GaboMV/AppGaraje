import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/notification_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

class NotificationRepository {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getMyNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      final notificaciones = (response.data['notificaciones'] as List)
          .map((e) => NotificacionModel.fromJson(e))
          .toList();
      final unreadCount = response.data['unreadCount'] as int;
      return {'notificaciones': notificaciones, 'unreadCount': unreadCount};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.put('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
