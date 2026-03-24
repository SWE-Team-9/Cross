import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/interceptors/error_interceptor.dart';

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late ErrorInterceptor interceptor;
  late MockErrorInterceptorHandler handler;

  setUp(() {
    interceptor = ErrorInterceptor();
    handler = MockErrorInterceptorHandler();
  });

  test('passes DioException to handler.next', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      message: 'Request failed',
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
        data: {'message': 'Unauthorized'},
      ),
    );

    interceptor.onError(error, handler);

    verify(() => handler.next(error)).called(1);
  });
}
