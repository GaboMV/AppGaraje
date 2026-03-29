import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../utils/app_logger.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth interceptor — injects token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();
          if (token != null) {
            AppLogger.info('[DioClient] Credencial inyectada en cabeceras de red para la vía: ${options.path}');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            AppLogger.warn('[DioClient] Ausencia de credenciales para consumo en ${options.path}');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          AppLogger.error('[DioClient] Interrupción operativa en ${e.requestOptions.path}. Estatus de retorno: ${e.response?.statusCode}');
          AppLogger.info('[DioClient] Trama residual: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    return dio;
  }

  // Reset instance (e.g., on logout)
  static void reset() => _instance = null;
}

// Generic error handler
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final msg = (data is Map && data['error'] != null)
        ? data['error'].toString()
        : e.message ?? 'Error desconocido';
    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  @override
  String toString() => message;
}
