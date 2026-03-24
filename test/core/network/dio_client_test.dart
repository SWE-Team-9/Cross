import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class _SuccessInterceptor extends Interceptor {
  _SuccessInterceptor(this.handlerFn);

  final Response<dynamic> Function(RequestOptions options) handlerFn;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(handlerFn(options));
  }
}

class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor(this.errorFn);

  final DioException Function(RequestOptions options) errorFn;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(errorFn(options));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioClient dioClient;
  late MockSecureStorage mockSecureStorage;
  late PersistCookieJar cookieJar;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    cookieJar = PersistCookieJar(
      storage: FileStorage(
        '${Directory.systemTemp.path}/cross_dio_client_test_cookies',
      ),
    );

    dioClient = DioClient(
      baseUrl: 'https://api.test.com',
      secureStorage: mockSecureStorage,
      cookieJar: cookieJar,
    );
  });

  group('DioClient', () {
    test('initializes dio with expected base options and interceptors', () {
      expect(dioClient.dio.options.baseUrl, 'https://api.test.com');
      expect(dioClient.dio.options.connectTimeout, const Duration(seconds: 30));
      expect(dioClient.dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(
        dioClient.dio.options.headers['Content-Type'],
        'application/json',
      );
      expect(dioClient.dio.interceptors, isNotEmpty);
    });

    test('get returns response from dio', () async {
      dioClient.dio.interceptors.insert(
        0,
        _SuccessInterceptor(
          (options) => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{
              'method': options.method,
              'path': options.path,
              'query': options.queryParameters,
            },
          ),
        ),
      );

      final response = await dioClient.get<dynamic>(
        '/profiles/me',
        queryParameters: const {'handle': 'ali'},
      );

      expect(response.statusCode, 200);
      expect(response.data['method'], 'GET');
      expect(response.data['path'], '/profiles/me');
      expect(response.data['query'], {'handle': 'ali'});
    });

    test('post returns response from dio', () async {
      dioClient.dio.interceptors.insert(
        0,
        _SuccessInterceptor(
          (options) => Response<dynamic>(
            requestOptions: options,
            statusCode: 201,
            data: <String, dynamic>{
              'method': options.method,
              'path': options.path,
              'data': options.data,
            },
          ),
        ),
      );

      final response = await dioClient.post<dynamic>(
        '/auth/login',
        data: const {'email': 'ali@example.com'},
      );

      expect(response.statusCode, 201);
      expect(response.data['method'], 'POST');
      expect(response.data['path'], '/auth/login');
      expect(response.data['data'], {'email': 'ali@example.com'});
    });

    test('put returns response from dio', () async {
      dioClient.dio.interceptors.insert(
        0,
        _SuccessInterceptor(
          (options) => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{
              'method': options.method,
              'path': options.path,
              'data': options.data,
            },
          ),
        ),
      );

      final response = await dioClient.put<dynamic>(
        '/profiles/me',
        data: const {'display_name': 'Ali'},
      );

      expect(response.statusCode, 200);
      expect(response.data['method'], 'PUT');
      expect(response.data['path'], '/profiles/me');
      expect(response.data['data'], {'display_name': 'Ali'});
    });

    test('delete returns response from dio', () async {
      dioClient.dio.interceptors.insert(
        0,
        _SuccessInterceptor(
          (options) => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{
              'method': options.method,
              'path': options.path,
              'data': options.data,
            },
          ),
        ),
      );

      final response = await dioClient.delete<dynamic>(
        '/tracks/123',
        data: const {'hard_delete': false},
      );

      expect(response.statusCode, 200);
      expect(response.data['method'], 'DELETE');
      expect(response.data['path'], '/tracks/123');
      expect(response.data['data'], {'hard_delete': false});
    });

    test('patch returns response from dio', () async {
      dioClient.dio.interceptors.insert(
        0,
        _SuccessInterceptor(
          (options) => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{
              'method': options.method,
              'path': options.path,
              'data': options.data,
            },
          ),
        ),
      );

      final response = await dioClient.patch<dynamic>(
        '/profiles/me',
        data: const {'bio': 'Updated bio'},
      );

      expect(response.statusCode, 200);
      expect(response.data['method'], 'PATCH');
      expect(response.data['path'], '/profiles/me');
      expect(response.data['data'], {'bio': 'Updated bio'});
    });

    test('get maps 404 DioException to NotFoundFailure', () async {
      dioClient.dio.interceptors.insert(
        0,
        _ErrorInterceptor(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 404,
              data: <String, dynamic>{'message': 'Profile not found'},
            ),
          ),
        ),
      );

      expect(
        () => dioClient.get<dynamic>('/profiles/missing'),
        throwsA(
          isA<NotFoundFailure>().having(
            (e) => e.message,
            'message',
            'Profile not found',
          ),
        ),
      );
    });

    test('post maps timeout DioException to NetworkFailure', () async {
      dioClient.dio.interceptors.insert(
        0,
        _ErrorInterceptor(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            message: 'timeout',
          ),
        ),
      );

      expect(
        () => dioClient.post<dynamic>(
          '/auth/login',
          data: const {'email': 'ali@example.com'},
        ),
        throwsA(
          isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            'Connection timeout. Please try again.',
          ),
        ),
      );
    });

    test('patch maps connection error DioException to NetworkFailure',
        () async {
      dioClient.dio.interceptors.insert(
        0,
        _ErrorInterceptor(
          (options) => DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet',
          ),
        ),
      );

      expect(
        () => dioClient.patch<dynamic>(
          '/profiles/me',
          data: const {'bio': 'Updated'},
        ),
        throwsA(
          isA<NetworkFailure>().having(
            (e) => e.message,
            'message',
            'No internet connection.',
          ),
        ),
      );
    });
  });
}
