import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/garage_model.dart';

class GarageRepository {
  final Dio _dio = DioClient.instance;

  Future<List<GarageModel>> searchGarages({
    String? fecha,
    String? horaInicio,
    String? horaFin,
    String? ubicacion,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (fecha != null) queryParams['fecha'] = fecha;
      if (horaInicio != null) queryParams['hora_inicio'] = horaInicio;
      if (horaFin != null) queryParams['hora_fin'] = horaFin;
      if (ubicacion != null) queryParams['ubicacion'] = ubicacion;

      final response = await _dio.get(
        ApiConstants.search,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      final list = data is List ? data : (data['garajes'] ?? data['results'] ?? []);
      return (list as List)
          .map((e) => GarageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<GarageModel> getGarageById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.garages}/$id');
      return GarageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
