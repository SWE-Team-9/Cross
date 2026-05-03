import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/search/data/datasources/search_remote_data_source.dart';
import 'package:soundcloud_clone/features/search/data/dto/search_models.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late SearchRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/fallback'));
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/fallback')),
    );
    registerFallbackValue(
      Response<dynamic>(
        requestOptions: RequestOptions(path: '/fallback'),
        data: {},
      ),
    );
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = SearchRemoteDataSourceImpl(mockDioClient);
  });

  group('SearchRemoteDataSourceImpl', () {
    const tQuery = 'test query';
    const tPage = 2;
    final tResponseData = {
      'data': {
        'tracks': [
          {
            'id': '1',
            'title': 'Test Track',
            'artistHandle': 'artist',
            'artwork_url': 'art.png',
            'stream_url': 'stream.mp3',
            'duration': 180,
            'views': 100,
            'likes_count': 10,
            'genre': 'electronic',
            'sharing': 'public',
            'created_at': '2023-01-01T00:00:00Z',
          }
        ],
        'users': [],
        'playlists': [],
      },
      'meta': {
        'current_page': 1,
        'total_results': 1,
        'total_pages': 1,
      },
    };

    test('returns SearchResponseModel on successful response', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: tResponseData,
            statusCode: 200,
          ));

      final result = await dataSource.search(tQuery, page: tPage);

      expect(result, isA<SearchResponseModel>());
      expect(result.tracks.length, 1);
      expect(result.tracks.first.title, 'Test Track');
      verify(() => mockDio.get(
            ApiConstants.globalSearch,
            queryParameters: {
              'q': tQuery,
              'page': tPage,
              'limit': 20,
            },
          )).called(1);
    });

    test('throws ServerFailure when response data is not Map', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            data: 'invalid data',
            statusCode: 200,
          ));

      expect(
        () async => await dataSource.search(tQuery),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('throws NetworkFailure on connection error', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      expect(
        () async => await dataSource.search(tQuery),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('throws AuthFailure on 401 status', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () async => await dataSource.search(tQuery),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws NotFoundFailure on 404 status', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () async => await dataSource.search(tQuery),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('throws ServerFailure on other errors', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () async => await dataSource.search(tQuery),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
