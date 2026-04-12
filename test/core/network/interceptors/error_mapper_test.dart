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
        expect(failure.message, 'Unauthorized');
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
        expect(failure.message,
            'Resource not found'); // Remove the period to match
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

      test('should map 403 to AuthFailure with fallback message', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('permission'));
      });

      test('should map 500 and 503 to ServerFailure messages', () {
        final error500 = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );
        final error503 = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );

        final failure500 = ErrorMapper.mapDioErrorToFailure(error500);
        final failure503 = ErrorMapper.mapDioErrorToFailure(error503);

        expect(failure500, isA<ServerFailure>());
        expect(failure500.message, contains('Server error'));
        expect(failure503, isA<ServerFailure>());
        expect(failure503.message, contains('later'));
      });

      test('should map unknown status code to generic ServerFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 418,
          ),
          type: DioExceptionType.badResponse,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Something went wrong');
      });

      test('should map send/receive timeout to NetworkFailure', () {
        final receiveTimeout = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );
        final sendTimeout = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.sendTimeout,
        );

        final receiveFailure = ErrorMapper.mapDioErrorToFailure(receiveTimeout);
        final sendFailure = ErrorMapper.mapDioErrorToFailure(sendTimeout);

        expect(receiveFailure, isA<NetworkFailure>());
        expect(sendFailure, isA<NetworkFailure>());
      });

      test('should map unknown DioException type to generic ServerFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );

        final failure = ErrorMapper.mapDioErrorToFailure(error);

        expect(failure, isA<ServerFailure>());
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
