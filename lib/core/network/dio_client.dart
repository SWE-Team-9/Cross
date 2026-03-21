import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/secure_storage.dart';
import 'error_mapper.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  final Dio dio;

  DioClient({
    required String baseUrl,
    required SecureStorage secureStorage,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {'Content-Type': 'application/json'},
            extra: {'withCredentials': true},
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage("${appDocDir.path}/.cookies/"),
    );

    dio.interceptors.addAll([
      CookieManager(cookieJar),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }
}
