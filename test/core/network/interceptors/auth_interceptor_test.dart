import 'package:flutter_test/flutter_test.dart';

// Third-party
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

// Project
import 'package:soundcloud_clone/core/network/interceptors/auth_interceptor.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

// ── Mock classes ──────────────────────────────────────────────────────────────
// With mocktail: no @GenerateMocks, no build_runner, no .mocks.dart file.
// Just extend Mock and implement the interface you want to fake.
class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class _MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late AuthInterceptor interceptor;
  late _MockSecureStorage mockSecureStorage;
  late Dio testDio;

  // registerFallbackValue is required by mocktail for any custom type
  // used with any() or captureAny() matchers.
  // Must be called once before all tests.
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
  });

  group('AuthInterceptor', () {
    // ── setDio ──────────────────────────────────────────────────────────────

    group('setDio', () {
      test('sets internal dio reference without throwing', () {
        // setDio returns void — MUST be called on its own line
        // Wrapping in expect(..., returnsNormally) confirms no exception thrown
        expect(
          () => interceptor.setDio(testDio),
          returnsNormally,
        );
      });
    });

    // ── onRequest ───────────────────────────────────────────────────────────

    group('onRequest', () {
      test('sets Content-Type to application/json for non-FormData requests',
          () {
        // arrange
        final options = RequestOptions(
          path: '/profiles/me',
          data: {'bio': 'test'},
        );
        final handler = _MockRequestInterceptorHandler();

        // act — void return, called on its own line
        interceptor.onRequest(options, handler);

        // assert — Content-Type set on options
        expect(options.headers['Content-Type'], 'application/json');

        // mocktail verify uses arrow function
        verify(() => handler.next(options)).called(1);
      });

      test('does not set Content-Type for FormData requests', () {
        // arrange — image upload uses multipart/form-data
        final options = RequestOptions(
          path: '/profiles/me/images/avatar',
          data: FormData(),
        );
        final handler = _MockRequestInterceptorHandler();

        // act
        interceptor.onRequest(options, handler);

        // assert — Content-Type must NOT be overridden for multipart
        expect(options.headers.containsKey('Content-Type'), isFalse);
        verify(() => handler.next(options)).called(1);
      });

      test('always calls handler.next() to continue the pipeline', () {
        // arrange
        final options = RequestOptions(path: '/profiles/me');
        final handler = _MockRequestInterceptorHandler();

        // act
        interceptor.onRequest(options, handler);

        // assert — request must not be blocked
        verify(() => handler.next(options)).called(1);
        verifyNoMoreInteractions(handler);
      });
    });

    // ── onError ─────────────────────────────────────────────────────────────

    group('onError', () {
      test('calls handler.next() for non-401 errors', () async {
        // arrange — 404 is not a token expiry, must pass through unchanged
        final err = DioException(
          requestOptions: RequestOptions(path: '/profiles/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/profiles/me'),
            statusCode: 404,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        // act — void return, awaited on its own line
        await interceptor.onError(err, handler);

        // assert
        verify(() => handler.next(err)).called(1);
        verifyNoMoreInteractions(handler);
      });

      test(
          'calls handler.next() for 401 on login (wrong credentials, not expiry)',
          () async {
        // arrange — 401 on /auth/login = wrong password
        // Interceptor must NOT attempt token refresh here
        final err = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        // act
        await interceptor.onError(err, handler);

        // assert — passes through, no refresh attempt
        verify(() => handler.next(err)).called(1);
      });

      test('calls handler.next() for 401 on refresh endpoint itself', () async {
        // arrange — 401 on /auth/refresh = refresh token expired
        // Must NOT retry to avoid infinite refresh loop
        final err = DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        // act
        await interceptor.onError(err, handler);

        // assert — error passes through, no retry
        verify(() => handler.next(err)).called(1);
      });

      test('passes error through when _dio is null and 401 on other endpoint',
          () async {
        // arrange — setDio() was never called so _dio is null
        // _refreshToken() will throw a null check error internally
        // The catch block in onError handles this silently
        // and calls handler.next() so the error is not swallowed
        final err = DioException(
          requestOptions: RequestOptions(path: '/profiles/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/profiles/me'),
            statusCode: 401,
          ),
        );
        final handler = _MockErrorInterceptorHandler();

        // act
        await interceptor.onError(err, handler);

        // assert — error must reach the caller even when refresh fails
        verify(() => handler.next(err)).called(1);
      });
    });
  });
}
