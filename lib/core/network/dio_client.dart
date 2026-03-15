import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'error_mapper.dart';
import '../storage/secure_storage.dart';

class DioClient {
  late final Dio dio;
  
  DioClient({
    required String baseUrl,
    required SecureStorage secureStorage,
  }) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add interceptors in order
    dio.interceptors.addAll([
      AuthInterceptor(secureStorage: secureStorage),
      ErrorInterceptor(),
      LoggingInterceptor(),

    ]);
  }
  
  // Helper methods for common requests
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }
  
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }
  
  // Add put, delete, etc.
}