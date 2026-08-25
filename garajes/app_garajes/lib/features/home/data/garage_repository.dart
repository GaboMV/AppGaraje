import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/garage_model.dart';
import '../domain/create_garage_request.dart';

class GarageRepository {
  final Dio _dio = DioClient.instance;

  Future<List<GarageModel>> searchGarages({
    String? fecha,
    String? horaInicio,
    String? horaFin,
    String? ubicacion,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (fecha != null) queryParams['fecha'] = fecha;
      if (horaInicio != null) queryParams['hora_inicio'] = horaInicio;
      if (horaFin != null) queryParams['hora_fin'] = horaFin;
      if (ubicacion != null) queryParams['ubicacion'] = ubicacion;
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;
      if (radius != null) queryParams['radio'] = radius;

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

  Future<List<GarageModel>> getMyGarages() async {
    try {
      final response = await _dio.get(ApiConstants.myGarages);
      final data = response.data;
      final list = data is List ? data : (data['garajes'] ?? []);
      return (list as List)
          .map((e) => GarageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<GarageModel> updateGarage(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.garages}/$id', data: data);
      return GarageModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<GarageModel> createGarage(FormData formData) async {
    try {
      final response = await _dio.post(
        ApiConstants.garages,
        data: formData,
      );
      final data = response.data as Map<String, dynamic>;
      return GarageModel.fromJson(data['garaje'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteGarage(String id) async {
    try {
      await _dio.delete('${ApiConstants.garages}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteGarageImage(String garageId, String imageId) async {
    try {
      await _dio.delete('${ApiConstants.garages}/$garageId/imagenes/$imageId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addServicioAdicional(String garageId, String nombre, double precio) async {
    try {
      await _dio.post(
        ApiConstants.garageServicios(garageId),
        data: {'nombre': nombre, 'precio': precio, 'es_por_dia': true},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteServicioAdicional(String garageId, String servicioId) async {
    try {
      await _dio.delete(ApiConstants.garageServicioAdicional(garageId, servicioId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> uploadImage(String garageId, MultipartFile file) async {
    try {
      final formData = FormData.fromMap({
        'imagen': file,
      });
      await _dio.post(
        '${ApiConstants.garages}/$garageId/imagenes',
        data: formData,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
