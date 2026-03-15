import 'package:dio/dio.dart';
import '../errors/failure.dart';

class ErrorMapper {
  static Failure mapDioErrorToFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkFailure('Connection timeout. Please try again.');

      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection.');

      case DioExceptionType.badResponse:
        return _mapStatusCodeToFailure(error.response);

      default:
        return ServerFailure('Something went wrong. Please try again.');
    }
  }

  static Failure _mapStatusCodeToFailure(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    switch (statusCode) {
      case 400:
        return ValidationFailure(_getErrorMessage(data) ?? 'Bad request');
      case 401:
        return AuthFailure('Unauthorized. Please login again.');
      case 403:
        return AuthFailure('You don\'t have permission.');
      case 404:
        return NotFoundFailure('Resource not found.');
      case 500:
        return ServerFailure('Server error. Please try later.');
      default:
        return ServerFailure(_getErrorMessage(data) ?? 'Something went wrong');
    }
  }

  static String? _getErrorMessage(dynamic data) {
    if (data is Map && data.containsKey('message')) {
      return data['message'] as String;
    }
    return null;
  }
}
