import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late ProfileRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(
      Options(),
    );
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    when(() => mockDioClient.dio).thenReturn(mockDio);
    dataSource = ProfileRemoteDataSourceImpl(mockDioClient);
  });

  group('getProfile', () {
    test('parses profile from direct response body', () async {
      when(() => mockDio.get('/api/v1/profiles/eyad')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/eyad'),
          data: <String, dynamic>{
            'id': '1',
            'handle': 'eyad',
            'display_name': 'Eyad',
            'bio': 'bio',
            'location': 'Cairo, Egypt',
            'avatar_url': 'https://cdn.example.com/avatar.png',
            'cover_photo_url': 'https://cdn.example.com/cover.png',
            'account_type': 'ARTIST',
            'favorite_genres': ['rock'],
            'social_links': <String, dynamic>{},
            'visibility': 'PUBLIC',
            'track_count': 4,
          },
        ),
      );

      final dto = await dataSource.getProfile('eyad');

      expect(dto.handle, 'eyad');
      expect(dto.displayName, 'Eyad');
      expect(dto.avatarUrl, 'https://cdn.example.com/avatar.png');
      expect(dto.coverPhotoUrl, 'https://cdn.example.com/cover.png');
      verify(() => mockDio.get('/api/v1/profiles/eyad')).called(1);
    });

    test('parses profile from nested profile key', () async {
      when(() => mockDio.get('/api/v1/profiles/eyad')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/eyad'),
          data: <String, dynamic>{
            'profile': <String, dynamic>{
              'handle': 'eyad',
              'display_name': 'Eyad',
              'account_type': 'LISTENER',
              'favorite_genres': <String>[],
              'social_links': <String, dynamic>{},
              'visibility': 'PUBLIC',
              'track_count': 0,
            },
          },
        ),
      );

      final dto = await dataSource.getProfile('eyad');

      expect(dto.handle, 'eyad');
      expect(dto.displayName, 'Eyad');
    });

    test('parses profile from string JSON response', () async {
      when(() => mockDio.get('/api/v1/profiles/eyad')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/eyad'),
          data:
              '{"handle":"eyad","display_name":"Eyad","account_type":"LISTENER","favorite_genres":[],"social_links":{},"visibility":"PUBLIC","track_count":0}',
        ),
      );

      final dto = await dataSource.getProfile('eyad');

      expect(dto.handle, 'eyad');
      expect(dto.displayName, 'Eyad');
    });
  });

  group('updateProfile', () {
    test('patches profile and parses nested data response', () async {
      final body = <String, dynamic>{
        'display_name': 'Ali',
        'bio': 'New bio',
      };

      when(() => mockDio.patch(
            '/api/v1/profiles/me',
            data: body,
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'handle': 'ali',
              'display_name': 'Ali',
              'bio': 'New bio',
              'account_type': 'LISTENER',
              'favorite_genres': <String>[],
              'social_links': <String, dynamic>{},
              'visibility': 'PUBLIC',
              'track_count': 0,
            },
          },
        ),
      );

      final dto = await dataSource.updateProfile(body);

      expect(dto.displayName, 'Ali');
      expect(dto.bio, 'New bio');
      verify(() => mockDio.patch(
            '/api/v1/profiles/me',
            data: body,
          )).called(1);
    });
  });

  group('uploadProfileImage', () {
    test('uploads avatar image and returns direct url', () async {
      when(() => mockDio.post(
            '/api/v1/profiles/me/images/avatar',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: '/api/v1/profiles/me/images/avatar'),
          data: <String, dynamic>{
            'url': 'https://cdn.example.com/avatar.png',
          },
        ),
      );

      final result = await dataSource.uploadProfileImage(
        imageType: ProfileImageType.AVATAR,
        filePath: 'test/test_assets/avatar.png',
      );

      expect(result, 'https://cdn.example.com/avatar.png');
      verify(() => mockDio.post(
            '/api/v1/profiles/me/images/avatar',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('uploads cover image and returns nested url', () async {
      when(() => mockDio.post(
            '/api/v1/profiles/me/images/cover',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: '/api/v1/profiles/me/images/cover'),
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'url': 'https://cdn.example.com/cover.png',
            },
          },
        ),
      );

      final result = await dataSource.uploadProfileImage(
        imageType: ProfileImageType.COVER,
        filePath: 'test/test_assets/cover.png',
      );

      expect(result, 'https://cdn.example.com/cover.png');
      verify(() => mockDio.post(
            '/api/v1/profiles/me/images/cover',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('throws FormatException when upload response has no url', () async {
      when(() => mockDio.post(
            '/api/v1/profiles/me/images/avatar',
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: '/api/v1/profiles/me/images/avatar'),
          data: <String, dynamic>{},
        ),
      );

      expect(
        () => dataSource.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: 'test/test_assets/avatar.png',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('checkHandleAvailable', () {
    test('returns availability from response body', () async {
      when(() => mockDio.get(
            '/api/v1/profiles/check-handle',
            queryParameters: <String, dynamic>{'handle': 'ali'},
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/check-handle'),
          data: <String, dynamic>{'available': true},
        ),
      );

      final result = await dataSource.checkHandleAvailable('ali');

      expect(result, isTrue);
      verify(() => mockDio.get(
            '/api/v1/profiles/check-handle',
            queryParameters: <String, dynamic>{'handle': 'ali'},
          )).called(1);
    });
  });

  group('getMyProfile', () {
    test('parses my profile from direct response body', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me'),
          data: <String, dynamic>{
            'handle': 'me',
            'display_name': 'Me',
            'account_type': 'ARTIST',
            'favorite_genres': <String>[],
            'social_links': <String, dynamic>{},
            'visibility': 'PUBLIC',
            'track_count': 10,
          },
        ),
      );

      final dto = await dataSource.getMyProfile();

      expect(dto.handle, 'me');
      verify(() => mockDio.get(any())).called(1);
    });

    test('rethrows and prints error on failure', () async {
      when(() => mockDio.get(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/v1/profiles/me'),
      ));

      expect(() => dataSource.getMyProfile(), throwsA(isA<DioException>()));
    });
  });

  group('getUserTracks', () {
    test('parses track list from wrapped response body', () async {
      when(() => mockDio.get('/api/v1/users/user-1/tracks')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/users/user-1/tracks'),
          data: <String, dynamic>{
            'tracks': [
              <String, dynamic>{
                'id': 'track-1',
                'title': 'Midnight Echoes',
                'visibility': 'PUBLIC',
              },
              <String, dynamic>{
                'id': 'track-2',
                'title': 'City Lights',
                'visibility': 'PRIVATE',
              },
            ],
          },
        ),
      );

      final tracks = await dataSource.getUserTracks('user-1');

      expect(tracks, hasLength(2));
      expect(tracks.first.id, 'track-1');
      expect(tracks.first.title, 'Midnight Echoes');
    });

    test('parses track list from direct array response', () async {
      when(() => mockDio.get('/api/v1/users/user-1/tracks')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/users/user-1/tracks'),
          data: [
            <String, dynamic>{
              'id': 'track-3',
              'title': 'Sunrise Loop',
              'visibility': 'PUBLIC',
            },
          ],
        ),
      );

      final tracks = await dataSource.getUserTracks('user-1');

      expect(tracks, hasLength(1));
      expect(tracks.single.id, 'track-3');
    });
  });

  group('updateExternalLinks', () {
    final Map<String, String> linksInput = {
      'twitter': 'https://twitter.com/user',
      'instagram': 'https://instagr.am/user',
    };

    test('updates links and parses list response from server', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me/links'),
          data: {
            'links': [
              {'platform': 'twitter', 'url': 'https://twitter.com/user'},
              {'platform': 'instagram', 'url': 'https://instagr.am/user'},
            ]
          },
        ),
      );

      final result = await dataSource.updateExternalLinks(linksInput);

      expect(result['twitter'], 'https://twitter.com/user');
      expect(result.length, 2);
    });

    test('returns original map if server response is empty/null', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me/links'),
          data: <String, dynamic>{'links': null}, // Explicitly null
        ),
      );

      final result = await dataSource.updateExternalLinks(linksInput);

      // Implementation returns externalLinks if parsed result is empty
      expect(result, equals(linksInput));
    });

    test('parses rawLinks when responseData is a direct List', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me/links'),
          data: [
            {'platform': 'facebook', 'url': 'https://fb.com'},
          ],
        ),
      );

      final result = await dataSource.updateExternalLinks(linksInput);

      expect(result['facebook'], 'https://fb.com');
    });

    test('parses rawLinks when responseData is a Map (not nested)', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me/links'),
          data: {'youtube': 'https://youtube.com'},
        ),
      );

      final result = await dataSource.updateExternalLinks(linksInput);

      expect(result['youtube'], 'https://youtube.com');
    });
  });

  group('_parseLinksMap logic (Internal branching)', () {
    test('handles list with empty or invalid items silently', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me/links'),
          data: [
            {'platform': ' ', 'url': ' '}, // Empty strings should be filtered
            {'platform': 'Spotify', 'url': 'https://spotify.com/user'},
            'not_a_map', // Should be ignored
          ],
        ),
      );

      final result = await dataSource.updateExternalLinks({});

      expect(result.containsKey('spotify'), isTrue);
      expect(result['spotify'], 'https://spotify.com/user');
      expect(result.length, 1);
    });

    test('returns empty map for totally invalid data types', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/profiles/me/links'),
          data: 12345, // Int triggers the "else { rawLinks = null; }" branch
        ),
      );

      final result = await dataSource.updateExternalLinks({});
      expect(result, isEmpty);
    });
  });

  group('General Error Handling Coverage', () {
    test('getProfile rethrows on exception', () async {
      when(() => mockDio.get(any())).thenThrow(Exception('Network Error'));
      expect(() => dataSource.getProfile('ali'), throwsException);
    });

    test('updateProfile rethrows on exception', () async {
      when(() => mockDio.patch(any(), data: any(named: 'data')))
          .thenThrow(Exception());
      expect(() => dataSource.updateProfile({}), throwsException);
    });

    test('checkHandleAvailable rethrows on exception', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(Exception());
      expect(() => dataSource.checkHandleAvailable('ali'), throwsException);
    });
  });
}
