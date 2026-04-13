import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/interactions/data/datasources/interactions_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late InteractionsRemoteDataSourceImpl dataSource;

  Response<dynamic> responseWith(dynamic data) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/test'),
      data: data,
    );
  }

  setUp(() {
    dioClient = MockDioClient();
    dataSource = InteractionsRemoteDataSourceImpl(dioClient);
  });

  group('mutation endpoints', () {
    test('likeTrack posts to like endpoint', () async {
      when(() => dioClient.post<dynamic>(ApiConstants.likeTrackPath('t1')))
          .thenAnswer((_) async => responseWith({}));

      await dataSource.likeTrack('t1');

      verify(() => dioClient.post<dynamic>(ApiConstants.likeTrackPath('t1')))
          .called(1);
    });

    test('unlikeTrack deletes like endpoint', () async {
      when(() => dioClient.delete<dynamic>(ApiConstants.likeTrackPath('t1')))
          .thenAnswer((_) async => responseWith({}));

      await dataSource.unlikeTrack('t1');

      verify(
        () => dioClient.delete<dynamic>(ApiConstants.likeTrackPath('t1')),
      ).called(1);
    });

    test('repostTrack posts to repost endpoint', () async {
      when(() => dioClient.post<dynamic>(ApiConstants.repostTrackPath('t1')))
          .thenAnswer((_) async => responseWith({}));

      await dataSource.repostTrack('t1');

      verify(() => dioClient.post<dynamic>(ApiConstants.repostTrackPath('t1')))
          .called(1);
    });

    test('unrepostTrack deletes repost endpoint', () async {
      when(() => dioClient.delete<dynamic>(ApiConstants.repostTrackPath('t1')))
          .thenAnswer((_) async => responseWith({}));

      await dataSource.unrepostTrack('t1');

      verify(
        () => dioClient.delete<dynamic>(ApiConstants.repostTrackPath('t1')),
      ).called(1);
    });
  });

  group('getTrackInteractionStatus', () {
    test('parses nested data map', () async {
      when(
        () => dioClient.get<dynamic>(
          ApiConstants.trackInteractionStatusPath('track-1'),
        ),
      ).thenAnswer(
        (_) async => responseWith({
          'data': {'is_liked': true, 'is_reposted': false},
        }),
      );

      final result = await dataSource.getTrackInteractionStatus('track-1');

      expect(result.isLiked, isTrue);
      expect(result.isReposted, isFalse);
    });

    test('parses string response body', () async {
      when(
        () => dioClient.get<dynamic>(
          ApiConstants.trackInteractionStatusPath('track-2'),
        ),
      ).thenAnswer(
        (_) async => responseWith(
          jsonEncode({'liked': false, 'reposted': true}),
        ),
      );

      final result = await dataSource.getTrackInteractionStatus('track-2');

      expect(result.isLiked, isFalse);
      expect(result.isReposted, isTrue);
    });
  });

  group('engagement lists', () {
    test('getTrackLikers passes pagination and parses payload', () async {
      when(
        () => dioClient.get<dynamic>(
          ApiConstants.trackLikersPath('track-1'),
          queryParameters: {'page': 2, 'limit': 10},
        ),
      ).thenAnswer(
        (_) async => responseWith({
          'data': {
            'items': [
              {
                'id': 'u1',
                'displayName': 'Ali',
                'avatarUrl': 'https://example.com/a.png',
              },
            ],
            'pagination': {
              'page': 2,
              'limit': 10,
              'total': 21,
              'totalPages': 3,
              'hasNextPage': true,
              'hasPreviousPage': true,
            },
          },
        }),
      );

      final result = await dataSource.getTrackLikers(
        'track-1',
        page: 2,
        limit: 10,
      );

      expect(result.items, hasLength(1));
      expect(result.page, 2);
      expect(result.limit, 10);
      expect(result.total, 21);
      expect(result.hasNextPage, isTrue);
    });

    test('getTrackReposters parses direct response map', () async {
      when(
        () => dioClient.get<dynamic>(
          ApiConstants.trackRepostersPath('track-1'),
          queryParameters: {'page': 1, 'limit': 20},
        ),
      ).thenAnswer(
        (_) async => responseWith({
          'items': [
            {
              'user': {
                'id': 'u2',
                'displayName': 'Sara',
              },
            },
          ],
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
            'hasNextPage': false,
            'hasPreviousPage': false,
          },
        }),
      );

      final result = await dataSource.getTrackReposters('track-1');

      expect(result.items.single.displayName, 'Sara');
      expect(result.hasNextPage, isFalse);
    });
  });

  group('liked and reposted tracks', () {
    test('getMyLikedTracks extracts nested track items', () async {
      when(() => dioClient.get<dynamic>(ApiConstants.myLikedTracks))
          .thenAnswer(
        (_) async => responseWith({
          'data': {
            'items': [
              {
                'track': {
                  'id': 'm1',
                  'title': 'Nested Track',
                  'visibility': 'public',
                },
              },
            ],
          },
        }),
      );

      final result = await dataSource.getMyLikedTracks();

      expect(result.single.id, 'm1');
      expect(result.single.title, 'Nested Track');
    });

    test('getMyRepostedTracks extracts direct list payload', () async {
      when(() => dioClient.get<dynamic>(ApiConstants.myRepostedTracks))
          .thenAnswer(
        (_) async => responseWith([
          {
            'id': 'm2',
            'title': 'Direct Track',
            'visibility': 'private',
          },
        ]),
      );

      final result = await dataSource.getMyRepostedTracks();

      expect(result.single.id, 'm2');
      expect(result.single.title, 'Direct Track');
    });

    test('extracts tracks from collection-like payloads', () async {
      when(() => dioClient.get<dynamic>(ApiConstants.myLikedTracks))
          .thenAnswer(
        (_) async => responseWith({
          'data': {
            'collection': [
              {
                'id': 'm3',
                'title': 'Collection Track',
                'visibility': 'public',
              },
            ],
          },
        }),
      );

      final result = await dataSource.getMyLikedTracks();

      expect(result.single.id, 'm3');
      expect(result.single.title, 'Collection Track');
    });

    test('returns empty list for unexpected payload shape', () async {
      when(() => dioClient.get<dynamic>(ApiConstants.myRepostedTracks))
          .thenAnswer((_) async => responseWith({'data': {'items': 'bad'}}));

      final result = await dataSource.getMyRepostedTracks();

      expect(result, isEmpty);
    });
  });
}
