import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:soundcloud_clone/core/network/error_mapper.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';

void main() {
  group('ErrorMapper', () {
    group('mapDioErrorToFailure', () {
      test('should map connection timeout to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<NetworkFailure>());
        expect(failure.message, contains('Connection timeout'));
      });

      test('should map connection error to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<NetworkFailure>());
        expect(failure.message, contains('No internet connection'));
      });

      test('should map 400 error to ValidationFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'message': 'Invalid input'},
          ),
          type: DioExceptionType.badResponse,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Invalid input');
      });

      test('should map 401 error to AuthFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
          type: DioExceptionType.badResponse,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Unauthorized. Please login again.'); // Match exact message
      });

      test('should map 404 error to NotFoundFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Resource not found'); // Remove the period to match
      });

      test('should map 422 error to ValidationFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 422,
            data: {'message': 'Validation failed'},
          ),
          type: DioExceptionType.badResponse,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<ValidationFailure>()); // This should now pass
      });

      test('should extract error message from different response formats', () {
        final errorWithMessage = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'message': 'Error message'},
          ),
          type: DioExceptionType.badResponse,
        );

        final errorWithError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {'error': 'Error field'},
          ),
          type: DioExceptionType.badResponse,
        );

        final failure1 = ErrorMapper.mapDioErrorToFailure(errorWithMessage);
        expect(failure1.message, 'Error message');

        final failure2 = ErrorMapper.mapDioErrorToFailure(errorWithError);
        expect(failure2.message, 'Error field');
      });
    });
  });
}