import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late SocialRepo repo;

  setUp(() {
    dio = MockDio();
    repo = SocialRepo(dio);
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  Response<dynamic> _response(dynamic data) => Response(
        data: data,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );

  DioException _404(String path) => DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: path),
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: path),
        ),
      );

  // ── getFollowers ──────────────────────────────────────────────────────────

  group('getFollowers', () {
    test('returns list when response is a List', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _response([
                {'id': 'u1', 'handle': 'alice', 'displayName': 'Alice'},
              ]));

      final result = await repo.getFollowers('usr1', 1);
      expect(result.length, 1);
      expect(result.first.username, 'alice');
    });

    test('returns list when response is Map with followers key', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _response({
                'followers': [
                  {'id': 'u2', 'handle': 'bob', 'displayName': 'Bob'},
                ]
              }));

      final result = await repo.getFollowers('usr1', 1);
      expect(result.length, 1);
      expect(result.first.username, 'bob');
    });

    test('returns empty list on 404', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_404('/followers'));

      final result = await repo.getFollowers('usr1', 1);
      expect(result, isEmpty);
    });

    test('rethrows non-404 DioException', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ''),
      ));

      expect(() => repo.getFollowers('usr1', 1), throwsA(isA<DioException>()));
    });
  });

  // ── getFollowing ──────────────────────────────────────────────────────────

  group('getFollowing', () {
    test('returns list when response is a List', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _response([
                {'id': 'u3', 'handle': 'carol', 'displayName': 'Carol'},
              ]));

      final result = await repo.getFollowing('usr1', 1);
      expect(result.length, 1);
    });

    test('returns list when response is Map with following key', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _response({
                'following': [
                  {'id': 'u4', 'handle': 'dave', 'displayName': 'Dave'},
                ]
              }));

      final result = await repo.getFollowing('usr1', 1);
      expect(result.length, 1);
    });

    test('returns empty list on 404', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_404('/following'));

      final result = await repo.getFollowing('usr1', 1);
      expect(result, isEmpty);
    });

    test('rethrows non-404 DioException', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ''),
      ));

      expect(() => repo.getFollowing('usr1', 1), throwsA(isA<DioException>()));
    });
  });

  // ── getBlockedUsers ───────────────────────────────────────────────────────

  group('getBlockedUsers', () {
    test('returns list when response is Map with blockedUsers key', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _response({
                'blockedUsers': [
                  {'id': 'u5', 'handle': 'eve', 'displayName': 'Eve'},
                ]
              }));

      final result = await repo.getBlockedUsers(1);
      expect(result.length, 1);
    });

    test('returns empty list on 404', () async {
      when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(_404('/blocked'));

      final result = await repo.getBlockedUsers(1);
      expect(result, isEmpty);
    });
  });

  // ── followUser ────────────────────────────────────────────────────────────

  group('followUser', () {
    test('returns isFollowing true and followersCount from response', () async {
      when(() => dio.post(any())).thenAnswer((_) async =>
          _response({'isFollowing': true, 'followersCount': 42}));

      final result = await repo.followUser('usr1');
      expect(result.isFollowing, isTrue);
      expect(result.followersCount, 42);
    });

    test('uses defaults when keys missing from response', () async {
      when(() => dio.post(any()))
          .thenAnswer((_) async => _response(<String, dynamic>{}));

      final result = await repo.followUser('usr1');
      expect(result.isFollowing, isTrue);
      expect(result.followersCount, 0);
    });
  });

  // ── unfollowUser ──────────────────────────────────────────────────────────

  group('unfollowUser', () {
    test('returns isFollowing false from response', () async {
      when(() => dio.delete(any())).thenAnswer((_) async =>
          _response({'isFollowing': false, 'followersCount': 10}));

      final result = await repo.unfollowUser('usr1');
      expect(result.isFollowing, isFalse);
      expect(result.followersCount, 10);
    });
  });

  // ── blockUser ─────────────────────────────────────────────────────────────

  group('blockUser', () {
    test('returns true when blockedUserId is non-empty', () async {
      when(() => dio.post(any())).thenAnswer(
          (_) async => _response({'blockedUserId': 'usr_999'}));

      expect(await repo.blockUser('usr_999'), isTrue);
    });

    test('returns false on DioException', () async {
      when(() => dio.post(any())).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ''),
      ));

      expect(await repo.blockUser('usr_999'), isFalse);
    });
  });

  // ── unblockUser ───────────────────────────────────────────────────────────

  group('unblockUser', () {
    test('returns true when blockedUserId is non-empty', () async {
      when(() => dio.delete(any())).thenAnswer(
          (_) async => _response({'blockedUserId': 'usr_999'}));

      expect(await repo.unblockUser('usr_999'), isTrue);
    });

    test('returns false on DioException', () async {
      when(() => dio.delete(any())).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ''),
      ));

      expect(await repo.unblockUser('usr_999'), isFalse);
    });
  });

  // ── getUserIdByHandle ─────────────────────────────────────────────────────

  group('getUserIdByHandle', () {
    test('returns id from response', () async {
      when(() => dio.get(any())).thenAnswer(
          (_) async => _response({'id': 'usr_123'}));

      final id = await repo.getUserIdByHandle('alice');
      expect(id, 'usr_123');
    });

    test('falls back to _id key', () async {
      when(() => dio.get(any())).thenAnswer(
          (_) async => _response({'_id': 'usr_456'}));

      final id = await repo.getUserIdByHandle('alice');
      expect(id, 'usr_456');
    });

    test('throws StateError when no id key found', () async {
      when(() => dio.get(any()))
          .thenAnswer((_) async => _response({'handle': 'alice'}));

      expect(
        () => repo.getUserIdByHandle('alice'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ── _asMap covers Map (non-typed) branch — lines 165,166 ─────────────────

  group('_asMap non-typed Map branch', () {
    test('handles plain Map response in followUser (line 165)', () async {
      final rawMap = <dynamic, dynamic>{
        'isFollowing': true,
        'followersCount': 7,
      };
      when(() => dio.post(any()))
          .thenAnswer((_) async => _response(rawMap));
      final result = await repo.followUser('usr1');
      expect(result.isFollowing, isTrue);
      expect(result.followersCount, 7);
    });

    test('throws StateError when _asMap receives non-Map value (line 166)', () async {
      when(() => dio.post(any()))
          .thenAnswer((_) async => _response('invalid'));
      expect(() => repo.followUser('usr1'), throwsA(isA<StateError>()));
    });
  });
}