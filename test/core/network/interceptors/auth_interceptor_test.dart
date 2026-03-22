import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/interceptors/auth_interceptor.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class _MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late AuthInterceptor interceptor;
  late _MockSecureStorage mockSecureStorage;
  late Dio testDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '')),
    );
  });

  setUp(() {
    mockSecureStorage = _MockSecureStorage();
    interceptor = AuthInterceptor(secureStorage: mockSecureStorage);
    testDio = Dio();

    when(() => mockSecureStorage.read(any())).thenAnswer((_) async => null);
  });

  group('AuthInterceptor', () {
    group('setDio', () {
      test('sets internal dio reference without throwing', () {
        expect(
          () => interceptor.setDio(testDio),
          returnsNormally,
        );
      });
    });

    group('onRequest', () {
      test(
          'sets Content-Type to application/json and adds Authorization for protected non-FormData requests',
          () async {
        final options = RequestOptions(
          path: '/profiles/me',
          data: {'bio': 'test'},
        );
        final handler = _MockRequestInterceptorHandler();

        when(() => mockSecureStorage.read('auth_token'))
            .thenAnswer((_) async => 'test-token-123');

        await interceptor.onRequest(options, handler);

        expect(options.headers['Content-Type'], 'application/json');
        expect(options.headers['Authorization'], 'Bearer test-token-123');
        verify(() => mockSecureStorage.read('auth_token')).called(1);
        verify(() => handler.next(options)).called(1);
      });

      test('does not override Content-Type for FormData requests', () async {
        final options = RequestOptions(
          path: '/profiles/me/images/avatar',
          data: FormData(),
        );
        final handler = _MockRequestInterceptorHandler();

        when(() => mockSecureStorage.read('auth_token'))
            .thenAnswer((_) async => null);

        await interceptor.onRequest(options, handler);

        expect(options.headers.containsKey('Content-Type'), isFalse);
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockSecureStorage.read('auth_token')).called(1);
        verify(() => handler.next(options)).called(1);
      });

      test('does not read token for auth endpoints', () async {
        final options = RequestOptions(
          path: '/auth/login',
          data: {'email': 'ali@example.com'},
        );
        final handler = _MockRequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(options.headers['Content-Type'], 'application/json');
        expect(options.headers.containsKey('Authorization'), isFalse);
        verifyNever(() => mockSecureStorage.read(any()));
        verify(() => handler.next(options)).called(1);
      });

      test('always calls handler.next() to continue the pipeline', () async {
        final options = RequestOptions(path: '/profiles/me');
        final handler = _MockRequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        verify(() => handler.next(options)).called(1);
      });
    });

    group('onError', () {
      test('calls handler.next() for non-401 errors', () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/profiles/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/profiles/me'),
            statusCode: 404,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
      });

      test(
          'calls handler.next() for 401 on login endpoint without refresh attempt',
          () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
      });

      test(
          'calls handler.next() for 401 on refresh endpoint to avoid refresh loop',
          () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
      });

      test(
          'passes error through when dio is not set and 401 happens on protected endpoint',
          () async {
        final err = DioException(
          requestOptions: RequestOptions(path: '/profiles/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/profiles/me'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(err, handler);

        verify(() => handler.next(err)).called(1);
      });
    });
  });
}
