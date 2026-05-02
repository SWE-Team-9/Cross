import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/feed/data/datasources/feed_remote_data_sources.dart';
import 'package:soundcloud_clone/features/feed/domain/entities/feed_item.dart';
import 'package:soundcloud_clone/features/feed/data/repositories/feed_repository_impl.dart';

class MockFeedRemoteDataSource extends Mock implements FeedRemoteDataSource {}

void main() {
  group('FeedRepositoryImpl', () {
    late MockFeedRemoteDataSource dataSource;
    late FeedRepositoryImpl repository;

    setUp(() {
      dataSource = MockFeedRemoteDataSource();
      repository = FeedRepositoryImpl(dataSource: dataSource);
    });

    test('getFeed returns data source page', () async {
      final page = ActivityFeedPageModel(
        items: const [],
        pagination: const FeedPaginationModel(
          page: 1,
          limit: 20,
          offset: 0,
          total: 0,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );
      when(() => dataSource.getFeed(page: 1)).thenAnswer(
        (_) async => page,
      );

      final result = await repository.getFeed(page: 1);

      // الـ repository بيحول ActivityFeedPageModel → FeedPage
      expect(result, isA<FeedPage>());
      expect(result.page, 1);
      expect(result.items, isEmpty);
    });

    test('toggleLike maps explicit and fallback values', () async {
      when(
        () => dataSource.toggleLike(trackId: 't1', currentlyLiked: false),
      ).thenAnswer((_) async => {'likesCount': 9, 'liked': true});
      when(
        () => dataSource.toggleLike(trackId: 't2', currentlyLiked: true),
      ).thenAnswer((_) async => <String, dynamic>{});

      final liked = await repository.toggleLike(
        trackId: 't1',
        currentlyLiked: false,
      );
      final fallback = await repository.toggleLike(
        trackId: 't2',
        currentlyLiked: true,
      );

      expect(liked.likesCount, 9);
      expect(liked.liked, isTrue);
      expect(fallback.likesCount, 0);
      expect(fallback.liked, isFalse);
    });

    test('toggleRepost maps explicit and fallback values', () async {
      when(
        () => dataSource.toggleRepost(trackId: 't1', currentlyReposted: false),
      ).thenAnswer((_) async => {'repostsCount': 4, 'reposted': true});
      when(
        () => dataSource.toggleRepost(trackId: 't2', currentlyReposted: true),
      ).thenAnswer((_) async => <String, dynamic>{});

      final reposted = await repository.toggleRepost(
        trackId: 't1',
        currentlyReposted: false,
      );
      final fallback = await repository.toggleRepost(
        trackId: 't2',
        currentlyReposted: true,
      );

      expect(reposted.repostsCount, 4);
      expect(reposted.reposted, isTrue);
      expect(fallback.repostsCount, 0);
      expect(fallback.reposted, isFalse);
    });

    test('getStreamUrl returns null for blocked playback', () async {
      when(() => dataSource.getTrackSource('blocked')).thenAnswer(
        (_) async => {'accessState': 'BLOCKED'},
      );
      when(() => dataSource.getTrackSource('playable')).thenAnswer(
        (_) async => {
          'accessState': 'PLAYABLE',
          'streamUrl': 'https://cdn/playable.mp3',
        },
      );

      expect(await repository.getStreamUrl('blocked'), isNull);
      expect(
        await repository.getStreamUrl('playable'),
        'https://cdn/playable.mp3',
      );
    });

    test('getPlaybackAccess applies blocked fallback and recordPlay delegates',
        () async {
      when(() => dataSource.getTrackSource('t1')).thenAnswer(
        (_) async => <String, dynamic>{},
      );
      when(() => dataSource.recordPlay('t1')).thenAnswer((_) async {});

      final access = await repository.getPlaybackAccess('t1');
      await repository.recordPlay('t1');

      expect(access.accessState, 'BLOCKED');
      expect(access.streamUrl, isNull);
      verify(() => dataSource.recordPlay('t1')).called(1);
    });
  });
}
