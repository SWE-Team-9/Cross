import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/search_models.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResponseModel> search(
    String query, {
    String? type,
    int page = 1,
    int limit = 20,
  });
}

@LazySingleton(as: SearchRemoteDataSource)
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final DioClient _client;

  SearchRemoteDataSourceImpl(this._client);

  @override
  Future<SearchResponseModel> search(
    String query, {
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.globalSearch,
        queryParameters: {
          'q': query.trim(),
          if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerFailure();
      }

      return SearchResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Failure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();

      default:
        final status = e.response?.statusCode;
        if (status == 401) return const AuthFailure();
        if (status == 404) return const NotFoundFailure();
        return const ServerFailure();
    }
  }
}