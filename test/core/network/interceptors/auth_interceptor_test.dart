import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/interceptors/auth_interceptor.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockDio extends Mock implements Dio {}

class _MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class _MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late AuthInterceptor interceptor;
  late _MockSecureStorage mockSecureStorage;
  late _MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/fallback'));
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/fallback')),
    );
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '/fallback')),
    );
  });

  setUp(() {
    mockSecureStorage = _MockSecureStorage();
    mockDio = _MockDio();
    interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
  });

  group('AuthInterceptor', () {
    test('setDio stores dio instance without throwing', () {
      expect(() => interceptor.setDio(mockDio), returnsNormally);
    });

    group('onRequest', () {
      test('sets json content type for non-FormData requests', () {
        final options = RequestOptions(
          path: '/profiles/me',
          data: <String, dynamic>{'bio': 'updated'},
        );
        final handler = _MockRequestInterceptorHandler();

        interceptor.onRequest(options, handler);

        expect(options.headers['Content-Type'], 'application/json');
        expect(options.headers.containsKey('Authorization'), isFalse);
        verifyNever(() => mockSecureStorage.read(any()));
        verify(() => handler.next(options)).called(1);
      });

      test('does not override content type for FormData requests', () {
        final options = RequestOptions(
          path: '/profiles/me/images/avatar',
          data: FormData(),
        );
        final handler = _MockRequestInterceptorHandler();

        interceptor.onRequest(options, handler);

        expect(options.headers.containsKey('Content-Type'), isFalse);
        expect(options.headers.containsKey('Authorization'), isFalse);
        verifyNever(() => mockSecureStorage.read(any()));
        verify(() => handler.next(options)).called(1);
      });

      test('does not add authorization header for auth endpoints', () {
        final options = RequestOptions(
          path: '/auth/login',
          data: <String, dynamic>{'email': 'ali@example.com'},
        );
        final handler = _MockRequestInterceptorHandler();

        interceptor.onRequest(options, handler);

        expect(options.headers['Content-Type'], 'application/json');
        expect(options.headers.containsKey('Authorization'), isFalse);
        verifyNever(() => mockSecureStorage.read(any()));
        verify(() => handler.next(options)).called(1);
      });
    });

    group('onError', () {
      test('passes through non-401 errors', () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/profiles/me'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/profiles/me'),
            statusCode: 404,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
      });

      test('passes through 401 on login endpoint without refresh', () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verifyNever(() => mockDio.post(any()));
        verify(() => handler.next(err)).called(1);
      });

      test('passes through 401 on refresh endpoint to avoid loop', () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verifyNever(() => mockDio.post(any()));
        verify(() => handler.next(err)).called(1);
      });

      test('passes through 401 when dio is not set', () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/profiles/me'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/profiles/me'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
      });

      test('refreshes and retries protected request on 401', () async {
        interceptor.setDio(mockDio);

        final requestOptions = RequestOptions(path: '/profiles/me');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
        );
        final retryResponse = Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 200,
          data: <String, dynamic>{'ok': true},
        );
        final handler = _MockErrorInterceptorHandler();

        when(() => mockDio.post('/api/v1/auth/refresh')).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
            statusCode: 200,
          ),
        );

        when(() => mockDio.fetch<dynamic>(requestOptions))
            .thenAnswer((_) async => retryResponse);

        await interceptor.onError(err, handler);

        verify(() => mockDio.post('/api/v1/auth/refresh')).called(1);
        verify(() => mockDio.fetch<dynamic>(requestOptions)).called(1);
        verify(() => handler.resolve(retryResponse)).called(1);
      });

      test('passes original error through when refresh fails', () async {
        interceptor.setDio(mockDio);

        final requestOptions = RequestOptions(path: '/profiles/me');
        final err = DioException(
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        when(() => mockDio.post('/api/v1/auth/refresh')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
              statusCode: 401,
            ),
          ),
        );

        await interceptor.onError(err, handler);

        verify(() => mockDio.post('/api/v1/auth/refresh')).called(1);
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => handler.next(err)).called(1);
      });
    });
  });
}
