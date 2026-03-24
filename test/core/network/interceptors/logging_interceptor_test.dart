import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/interceptors/logging_interceptor.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late LoggingInterceptor interceptor;
  late MockRequestInterceptorHandler requestHandler;
  late MockResponseInterceptorHandler responseHandler;
  late MockErrorInterceptorHandler errorHandler;

  setUp(() {
    interceptor = LoggingInterceptor();
    requestHandler = MockRequestInterceptorHandler();
    responseHandler = MockResponseInterceptorHandler();
    errorHandler = MockErrorInterceptorHandler();
  });

  test('passes request to handler.next', () {
    final options = RequestOptions(
      path: '/profiles/me',
      method: 'GET',
      headers: {'Authorization': 'Bearer token'},
      data: {'test': true},
    );

    interceptor.onRequest(options, requestHandler);

    verify(() => requestHandler.next(options)).called(1);
  });

  test('passes response to handler.next', () {
    final response = Response(
      requestOptions: RequestOptions(path: '/profiles/me'),
      statusCode: 200,
      data: {'ok': true},
    );

    interceptor.onResponse(response, responseHandler);

    verify(() => responseHandler.next(response)).called(1);
  });

  test('passes error to handler.next', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/profiles/me'),
      message: 'Something failed',
      response: Response(
        requestOptions: RequestOptions(path: '/profiles/me'),
        statusCode: 500,
        data: {'message': 'Server error'},
      ),
    );

    interceptor.onError(error, errorHandler);

    verify(() => errorHandler.next(error)).called(1);
  });
}
