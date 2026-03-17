import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/reservation_model.dart';

class ReservationRepository {
  final Dio _dio = DioClient.instance;

  Future<ReservationModel> createReservation({
    required String garageId,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    required String mensaje,
    List<String> serviciosIds = const [],
  }) async {
    try {
      final response = await _dio.post(ApiConstants.reservations, data: {
        'garaje_id': garageId,
        'fecha': fecha,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'mensaje_inquilino': mensaje,
        if (serviciosIds.isNotEmpty) 'servicios_ids': serviciosIds,
      });
      final data = response.data;
      final reservationJson = data['reserva'] ?? data;
      return ReservationModel.fromJson(reservationJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ReservationModel> payReservation({
    required String reservationId,
    required String metodoPago, // 'qr' or 'tarjeta'
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.payReservation(reservationId),
        data: {'metodo_pago': metodoPago},
      );
      final data = response.data;
      final reservationJson = data['reserva'] ?? data;
      return ReservationModel.fromJson(reservationJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> rateReservation({
    required String reservationId,
    required int calificacion,
    String? comentario,
  }) async {
    try {
      await _dio.post(ApiConstants.rate(reservationId), data: {
        'calificacion': calificacion,
        if (comentario != null) 'comentario': comentario,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> checkIn(String reservationId) async {
    try {
      await _dio.post(ApiConstants.checkIn(reservationId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> checkOut(String reservationId) async {
    try {
      await _dio.post(ApiConstants.checkOut(reservationId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ReservationModel>> getMyReservations() async {
    try {
      final response = await _dio.get(ApiConstants.myReservations);
      final data = response.data;
      final list = data is List ? data : (data['reservas'] ?? []);
      return (list as List)
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ReservationModel>> getOwnerReservations() async {
    try {
      final response = await _dio.get(ApiConstants.ownerReservations);
      final data = response.data;
      final list = data is List ? data : (data['reservas'] ?? []);
      return (list as List)
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ReservationModel> getReservationById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.reservationById(id));
      final data = response.data;
      final reservationJson = data['reserva'] ?? data;
      return ReservationModel.fromJson(reservationJson as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
