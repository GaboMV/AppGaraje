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
    required bool aceptaTerminos,
    List<String> serviciosIds = const [],
    List<String> categoriasVenta = const [],
    String? tipoCobro = 'POR_HORA',
  }) async {
    try {
      final response = await _dio.post(ApiConstants.reservations, data: {
        'id_garaje': garageId,
        'fecha': fecha,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'mensaje_inicial': mensaje,
        'acepto_terminos_responsabilidad': aceptaTerminos,
        'servicios_extra': serviciosIds.map((id) => {'id_servicio': id, 'cantidad': 1}).toList(),
        'categorias_venta': categoriasVenta,
        'tipo_cobro': tipoCobro,
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

  Future<void> acceptForChat(String id) async {
    try {
      await _dio.post(ApiConstants.acceptForChat(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> confirmReservation(String id) async {
    try {
      await _dio.post(ApiConstants.confirmReservation(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> rejectReservation(String id) async {
    try {
      await _dio.post(ApiConstants.rejectReservation(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String reservationId) async {
    try {
      final response = await _dio.get(ApiConstants.chatHistory(reservationId));
      final data = response.data;
      final list = data['mensajes'] as List? ?? [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
