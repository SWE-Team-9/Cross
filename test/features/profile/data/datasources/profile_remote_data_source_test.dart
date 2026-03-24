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
}
