import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SocialRepo repo;

  setUp(() {
    mockDio = MockDio();
    repo = SocialRepo(mockDio);
  });

  group('getFollowers', () {
    test('parses direct list response', () async {
      when(
        () => mockDio.get(
          ApiConstants.followersPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: [
            {'id': '1', 'username': 'ali'}
          ],
        ),
      );

      final result = await repo.getFollowers('u1', 1);
      expect(result.length, 1);
      expect(result.first.username, 'ali');
    });

    test('parses followers key response', () async {
      when(
        () => mockDio.get(
          ApiConstants.followersPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'followers': [
              {'id': '1', 'username': 'ali'}
            ]
          },
        ),
      );

      final result = await repo.getFollowers('u1', 1);
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('returns empty list on 404', () async {
      when(
        () => mockDio.get(
          ApiConstants.followersPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
        ),
      );

      final result = await repo.getFollowers('u1', 1);
      expect(result, isEmpty);
    });

    test('rethrows non-404 dio exception', () async {
      when(
        () => mockDio.get(
          ApiConstants.followersPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
        ),
      );

      expect(() => repo.getFollowers('u1', 1), throwsA(isA<DioException>()));
    });

    test('respects custom limit parameter', () async {
      when(
        () => mockDio.get(
          ApiConstants.followersPath('u1'),
          queryParameters: {'page': 2, 'limit': 10},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: <dynamic>[],
        ),
      );

      final result = await repo.getFollowers('u1', 2, limit: 10);
      expect(result, isEmpty);
    });
  });

  group('getFollowing', () {
    test('parses following key response', () async {
      when(
        () => mockDio.get(
          ApiConstants.followingPath('u1'),
          queryParameters: {'page': 2, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'following': [
              {'id': '2', 'username': 'omar'}
            ]
          },
        ),
      );

      final result = await repo.getFollowing('u1', 2);
      expect(result.length, 1);
      expect(result.first.username, 'omar');
    });

    test('returns empty list on unsupported shape', () async {
      when(
        () => mockDio.get(
          ApiConstants.followingPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'unexpected': 'shape'},
        ),
      );

      final result = await repo.getFollowing('u1', 1);
      expect(result, isEmpty);
    });

    test('returns empty list on 404', () async {
      when(
        () => mockDio.get(
          ApiConstants.followingPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
        ),
      );

      final result = await repo.getFollowing('u1', 1);
      expect(result, isEmpty);
    });

    test('rethrows non-404 dio exception', () async {
      when(
        () => mockDio.get(
          ApiConstants.followingPath('u1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 503,
          ),
        ),
      );

      expect(() => repo.getFollowing('u1', 1), throwsA(isA<DioException>()));
    });
  });

  group('getBlockedUsers', () {
    test('parses blockedUsers key response', () async {
      when(
        () => mockDio.get(
          ApiConstants.blockedUsersPath,
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'blockedUsers': [
              {'id': 'u99', 'username': 'blocked'}
            ]
          },
        ),
      );

      final result = await repo.getBlockedUsers(1);
      expect(result.length, 1);
      expect(result.first.id, 'u99');
    });

    test('returns empty list on 404', () async {
      when(
        () => mockDio.get(
          ApiConstants.blockedUsersPath,
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 404,
          ),
        ),
      );

      final result = await repo.getBlockedUsers(1);
      expect(result, isEmpty);
    });

    test('rethrows non-404 dio exception', () async {
      when(
        () => mockDio.get(
          ApiConstants.blockedUsersPath,
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
        ),
      );

      expect(() => repo.getBlockedUsers(1), throwsA(isA<DioException>()));
    });

    test('respects custom limit parameter', () async {
      when(
        () => mockDio.get(
          ApiConstants.blockedUsersPath,
          queryParameters: {'page': 1, 'limit': 5},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: <dynamic>[],
        ),
      );

      final result = await repo.getBlockedUsers(1, limit: 5);
      expect(result, isEmpty);
    });
  });

  group('action methods', () {
    test('followUser posts and returns isFollowing true', () async {
      when(() => mockDio.post(ApiConstants.followUserPath('u1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'isFollowing': true, 'followersCount': 1},
        ),
      );

      final result = await repo.followUser('u1');
      expect(result.isFollowing, isTrue);
      expect(result.followersCount, 1);
      verify(() => mockDio.post(ApiConstants.followUserPath('u1'))).called(1);
    });

    test('followUser throws DioException on network error', () async {
      when(() => mockDio.post(ApiConstants.followUserPath('u1'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      expect(() => repo.followUser('u1'), throwsA(isA<DioException>()));
    });

    test('unfollowUser deletes and returns isFollowing false', () async {
      when(() => mockDio.delete(ApiConstants.followUserPath('u1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'isFollowing': false},
        ),
      );

      final result = await repo.unfollowUser('u1');
      expect(result.isFollowing, isFalse);
      expect(result.followersCount, isNull);
      verify(() => mockDio.delete(ApiConstants.followUserPath('u1'))).called(1);
    });

    test('unfollowUser throws DioException on network error', () async {
      when(() => mockDio.delete(ApiConstants.followUserPath('u1'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      expect(() => repo.unfollowUser('u1'), throwsA(isA<DioException>()));
    });

    test('blockUser posts and returns true', () async {
      when(() => mockDio.post(ApiConstants.blockUserPath('u1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'blockedUserId': 'u1'},
        ),
      );

      final result = await repo.blockUser('u1');
      expect(result, isTrue);
      verify(() => mockDio.post(ApiConstants.blockUserPath('u1'))).called(1);
    });

    test('blockUser returns false on DioException', () async {
      when(() => mockDio.post(ApiConstants.blockUserPath('u1'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      final result = await repo.blockUser('u1');
      expect(result, isFalse);
    });

    test('blockUser returns false when blockedUserId is empty', () async {
      when(() => mockDio.post(ApiConstants.blockUserPath('u1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'blockedUserId': ''},
        ),
      );

      final result = await repo.blockUser('u1');
      expect(result, isFalse);
    });

    test('unblockUser deletes and returns true', () async {
      when(() => mockDio.delete(ApiConstants.blockUserPath('u1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'blockedUserId': 'u1'},
        ),
      );

      final result = await repo.unblockUser('u1');
      expect(result, isTrue);
      verify(() => mockDio.delete(ApiConstants.blockUserPath('u1'))).called(1);
    });

    test('unblockUser returns false on DioException', () async {
      when(() => mockDio.delete(ApiConstants.blockUserPath('u1'))).thenThrow(
        DioException(requestOptions: RequestOptions(path: '')),
      );

      final result = await repo.unblockUser('u1');
      expect(result, isFalse);
    });

    test('unblockUser returns false when blockedUserId is empty', () async {
      when(() => mockDio.delete(ApiConstants.blockUserPath('u1'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'blockedUserId': ''},
        ),
      );

      final result = await repo.unblockUser('u1');
      expect(result, isFalse);
    });
  });

  group('getUserIdByHandle', () {
    test('returns id from profile response', () async {
      when(() => mockDio.get(ApiConstants.profileByHandlePath('ali')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'id': 'user-1'},
        ),
      );

      final result = await repo.getUserIdByHandle('ali');
      expect(result, 'user-1');
    });

    test('returns fallback _id from profile response', () async {
      when(() => mockDio.get(ApiConstants.profileByHandlePath('ali')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'_id': 'user-2'},
        ),
      );

      final result = await repo.getUserIdByHandle('ali');
      expect(result, 'user-2');
    });

    test('throws when profile response has no id', () async {
      when(() => mockDio.get(ApiConstants.profileByHandlePath('ali')))
          .thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'username': 'ali'},
        ),
      );

      expect(
        () => repo.getUserIdByHandle('ali'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
