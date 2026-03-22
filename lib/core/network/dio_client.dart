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
  final SecureStorage secureStorage;

  DioClient({
    required String baseUrl,
    required this.secureStorage,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: const {'Content-Type': 'application/json'},
            extra: {'withCredentials': true}, // تفعيل الكوكيز بناءً على صورتك
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

      // Auth Interceptor لتجديد الـ Token تلقائياً
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(SecureStorage.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // إذا كان الخطأ 401 (غير مصرح به) يعني أن التوكن قد انتهى
          if (e.response?.statusCode == 401) {
            final refreshToken =
                await secureStorage.read(SecureStorage.refreshTokenKey);

            if (refreshToken != null) {
              try {
                // محاولة طلب توكن جديد باستخدام الـ Refresh Token
                // ملاحظة: تأكد من مسار الـ refresh الصحيح في الـ API الخاص بك
                final response = await dio.post('/api/v1/auth/refresh', data: {
                  'refresh_token': refreshToken,
                });

                if (response.statusCode == 200) {
                  final newToken = response.data['access_token'];
                  final newRefresh = response.data['refresh_token'];

                  // حفظ البيانات الجديدة
                  await secureStorage.write(
                      SecureStorage.accessTokenKey, newToken);
                  await secureStorage.write(
                      SecureStorage.refreshTokenKey, newRefresh);

                  // إعادة الطلب الأصلي الذي فشل باستخدام التوكن الجديد
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final retryResponse = await dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (err) {
                // فشل التجديد كلياً (الـ Refresh Token أيضاً انتهى)
                await secureStorage.clearAuthData();
                // هنا يفضل توجيه المستخدم لصفحة Login عبر الـ Router الخاص بك
              }
            }
          }
          return handler.next(e);
        },
      ),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  // الدوال المساعدة للطلبات
  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await dio.get<T>(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> put<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await dio.put<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> delete<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await dio.delete<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }

  Future<Response<T>> patch<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      return await dio.patch<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw ErrorMapper.mapDioErrorToFailure(e);
    }
  }
}
