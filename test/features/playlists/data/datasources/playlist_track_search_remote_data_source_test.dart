import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/data/datasources/playlist_track_search_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late PlaylistTrackSearchRemoteDataSource dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = PlaylistTrackSearchRemoteDataSource(dioClient);
  });

  group('getMyTracks', () {
    test('resolves current user id and parses track payload', () async {
      when(() => dioClient.get('/api/v1/auth/me')).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/auth/me'),
          data: {
            'user': {'id': 'user-1'},
          },
        ),
      );
      when(() => dioClient.get(
            '/api/v1/users/user-1/tracks',
            queryParameters: {'page': 1, 'limit': 50},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/users/user-1/tracks'),
          data: {
            'tracks': [
              {
                'trackId': 'trk_mine',
                'title': 'My Upload',
                'artistName': 'Ali',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getMyTracks();

      expect(result, hasLength(1));
      expect(result.first.id, 'trk_mine');
      expect(result.first.title, 'My Upload');
      expect(result.first.artist, 'Ali');
    });

    test('uses provided user id without calling current user endpoint',
        () async {
      when(() => dioClient.get(
            '/api/v1/users/user-2/tracks',
            queryParameters: {'page': 1, 'limit': 50},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/users/user-2/tracks'),
          data: const {'tracks': <dynamic>[]},
        ),
      );

      final result = await dataSource.getMyTracks(userId: 'user-2');

      expect(result, isEmpty);
      verifyNever(() => dioClient.get('/api/v1/auth/me'));
    });
  });

  group('searchTracks', () {
    test('returns empty list for blank query and avoids network call',
        () async {
      final result = await dataSource.searchTracks('   ');

      expect(result, isEmpty);
      verifyNever(() =>
          dioClient.get(any(), queryParameters: any(named: 'queryParameters')));
    });

    test('uses q parameter and parses track payload', () async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'layali', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: {
            'tracks': [
              {
                'trackId': 'trk_1',
                'title': 'Layali',
                'artistName': 'Ahmed',
                'likesCount': 7,
              },
            ],
          },
        ),
      );

      final result = await dataSource.searchTracks('layali');

      expect(result, hasLength(1));
      expect(result.first.id, 'trk_1');
      expect(result.first.title, 'Layali');
      expect(result.first.artist, 'Ahmed');
      expect(result.first.likesCount, 7);
    });

    test('falls back to query parameter when q returns no data', () async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'echo', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: const {'tracks': <dynamic>[]},
        ),
      );

      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'query': 'echo', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: {
            'data': {
              'tracks': [
                {
                  'id': 'trk_2',
                  'title': 'Echoes',
                  'artistName': 'Noor',
                },
              ],
            },
          },
        ),
      );

      final result = await dataSource.searchTracks('echo');

      expect(result, hasLength(1));
      expect(result.first.id, 'trk_2');
      verify(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'echo', 'limit': 25},
          )).called(1);
      verify(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'query': 'echo', 'limit': 25},
          )).called(1);
    });

    test('deduplicates tracks by id', () async {
      when(() => dioClient.get(
            '/api/v1/tracks',
            queryParameters: {'q': 'dup', 'limit': 25},
          )).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/v1/tracks'),
          data: {
            'tracks': [
              {'id': 'trk_3', 'title': 'A', 'artistName': 'X'},
              {'trackId': 'trk_3', 'title': 'B', 'artistName': 'Y'},
            ],
          },
        ),
      );

      final result = await dataSource.searchTracks('dup');

      expect(result, hasLength(1));
      expect(result.first.id, 'trk_3');
    });
  });
}
