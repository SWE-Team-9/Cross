// ─────────────────────────────────────────────────────────────────────────────
//  feed_cubit_test.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:soundcloud_clone/features/feed/presentation/bloc/feed_cubit.dart';
import 'package:soundcloud_clone/features/feed/presentation/bloc/feed_state.dart';
import 'package:soundcloud_clone/features/feed/domain/usecases/get_feed.dart';
import 'package:soundcloud_clone/features/feed/domain/usecases/toggle_like.dart';
import 'package:soundcloud_clone/features/feed/domain/usecases/toggle_repost.dart';
import '.././test_helpers.dart';
import 'package:soundcloud_clone/features/feed/domain/entities/feed_item.dart';
// ─── Builder ──────────────────────────────────────────────────────────────────

FeedCubit buildCubit(FakeFeedRepository repo) => FeedCubit(
      getFeed: GetFeedUseCase(repo),
      toggleLike: ToggleLikeUseCase(repo),
      toggleRepost: ToggleRepostUseCase(repo),
      repository: repo,
    );

void main() {
  late FakeFeedRepository repo;

  setUp(() => repo = FakeFeedRepository());

  // ─── Initial state ─────────────────────────────────────────────────────────

  group('initial state', () {
    test('starts as FeedLoading on following tab', () {
      final cubit = buildCubit(repo);
      expect(cubit.state, isA<FeedLoading>());
      expect(cubit.state.tab, FeedTab.following);
      cubit.close();
    });
  });

  // ─── initialize ────────────────────────────────────────────────────────────

  group('initialize', () {
    blocTest<FeedCubit, FeedState>(
      'emits [FeedLoading, FeedLoaded] on success',
      build: () => buildCubit(repo),
      act: (c) => c.initialize(),
      expect: () => [isA<FeedLoading>(), isA<FeedLoaded>()],
    );

    blocTest<FeedCubit, FeedState>(
      'loaded state has items and correct tab',
      build: () {
        repo.feedPageToReturn = makeFeedPage(count: 3);
        return buildCubit(repo);
      },
      act: (c) => c.initialize(),
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>().having((s) => s.items.length, 'items count', 3),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'emits [FeedLoading, FeedEmpty] when no items',
      build: () {
        repo.feedPageToReturn = makeEmptyPage();
        return buildCubit(repo);
      },
      act: (c) => c.initialize(),
      expect: () => [isA<FeedLoading>(), isA<FeedEmpty>()],
    );

    blocTest<FeedCubit, FeedState>(
      'emits [FeedLoading, FeedError] on exception',
      build: () {
        repo.getFeedError = Exception('Network error');
        return buildCubit(repo);
      },
      act: (c) => c.initialize(),
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedError>().having(
          (s) => s.message,
          'message',
          contains('Network error'),
        ),
      ],
    );

    blocTest<FeedCubit, FeedState>(
      'loaded state hasMore=true when more pages exist',
      build: () {
        repo.feedPageToReturn = makeFeedPage(hasMore: true);
        return buildCubit(repo);
      },
      act: (c) => c.initialize(),
      verify: (c) => expect((c.state as FeedLoaded).hasMore, true),
    );

    blocTest<FeedCubit, FeedState>(
      'loaded state hasMore=false on last page',
      build: () {
        repo.feedPageToReturn = makeFeedPage(hasMore: false);
        return buildCubit(repo);
      },
      act: (c) => c.initialize(),
      verify: (c) => expect((c.state as FeedLoaded).hasMore, false),
    );
  });

  // ─── setTab ────────────────────────────────────────────────────────────────

  group('setTab', () {
    blocTest<FeedCubit, FeedState>(
      'switches to discover tab and reloads',
      build: () => buildCubit(repo),
      act: (c) async {
        await c.initialize();
        await c.setTab(FeedTab.discover);
      },
      verify: (c) {
        expect(c.state.tab, FeedTab.discover);
        expect(c.state, isA<FeedLoaded>());
      },
    );

    blocTest<FeedCubit, FeedState>(
      'does not reload if same tab is already loaded',
      build: () => buildCubit(repo),
      act: (c) async {
        await c.initialize();
        await c.setTab(FeedTab.following);
      },
      verify: (_) => expect(repo.getCalls.length, 1),
    );

    blocTest<FeedCubit, FeedState>(
      'calls getFeed with discover key when switching to discover',
      build: () => buildCubit(repo),
      act: (c) async {
        await c.initialize();
        await c.setTab(FeedTab.discover);
      },
      verify: (_) => expect(repo.getCalls, contains('discover:1')),
    );

    blocTest<FeedCubit, FeedState>(
      'resets items when switching tabs',
      build: () {
        repo.feedPageToReturn = makeFeedPage(count: 3);
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        repo.feedPageToReturn = makeFeedPage(tab: 'discover', count: 2);
        await c.setTab(FeedTab.discover);
      },
      verify: (c) => expect((c.state as FeedLoaded).items.length, 2),
    );
  });

  // ─── loadMore ──────────────────────────────────────────────────────────────

  group('loadMore', () {
    blocTest<FeedCubit, FeedState>(
      'appends items from next page',
      build: () {
        repo.feedPageToReturn = makeFeedPage(count: 3, hasMore: true);
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        repo.feedPageToReturn = makeFeedPage(count: 3, hasMore: false, page: 2);
        await c.loadMore();
      },
      verify: (c) => expect((c.state as FeedLoaded).items.length, 6),
    );

    blocTest<FeedCubit, FeedState>(
      'does nothing when hasMore=false',
      build: () {
        repo.feedPageToReturn = makeFeedPage(hasMore: false);
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        await c.loadMore();
      },
      verify: (_) => expect(repo.getCalls.length, 1),
    );

    blocTest<FeedCubit, FeedState>(
      'does nothing when already loading more',
      build: () {
        repo.feedPageToReturn = makeFeedPage(hasMore: true);
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        final loaded = c.state as FeedLoaded;
        // ignore: invalid_use_of_protected_member
        c.emit(loaded.copyWith(isLoadingMore: true));
        await c.loadMore();
      },
      verify: (_) => expect(repo.getCalls.length, 1),
    );

    blocTest<FeedCubit, FeedState>(
      'does nothing when state is not FeedLoaded',
      build: () => buildCubit(repo),
      act: (c) => c.loadMore(),
      verify: (_) => expect(repo.getCalls, isEmpty),
    );
  });

  // ─── refresh ───────────────────────────────────────────────────────────────

  group('refresh', () {
    blocTest<FeedCubit, FeedState>(
      'replaces items with fresh page 1',
      build: () {
        repo.feedPageToReturn = makeFeedPage(count: 3);
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        repo.feedPageToReturn = makeFeedPage(count: 5);
        await c.refresh();
      },
      verify: (c) => expect((c.state as FeedLoaded).items.length, 5),
    );

    blocTest<FeedCubit, FeedState>(
      'calls getFeed with page=1 on refresh',
      build: () => buildCubit(repo),
      act: (c) async {
        await c.initialize();
        await c.refresh();
      },
      verify: (_) => expect(repo.getCalls, ['following:1', 'following:1']),
    );

    blocTest<FeedCubit, FeedState>(
      'isRefreshing=false after refresh completes',
      build: () => buildCubit(repo),
      act: (c) async {
        await c.initialize();
        await c.refresh();
      },
      verify: (c) => expect((c.state as FeedLoaded).isRefreshing, false),
    );
  });

  // ─── handleLike ────────────────────────────────────────────────────────────

  group('handleLike', () {
    blocTest<FeedCubit, FeedState>(
      'immediately flips liked=true (optimistic)',
      build: () {
        repo.feedPageToReturn = makeFeedPage(count: 1);
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        final trackId = (c.state as FeedLoaded).items.first.track.trackId;
        await c.handleLike(trackId);
      },
      verify: (c) => expect(
        (c.state as FeedLoaded).items.first.track.userState.liked,
        true,
      ),
    );

    blocTest<FeedCubit, FeedState>(
      'increments likesCount optimistically',
      build: () {
        repo.feedPageToReturn = FeedPage(
          items: [makeItem(likes: 100, liked: false)],
          page: 1,
          hasMore: false,
          totalItems: 1,
        );
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        await c.handleLike('trk_001');
      },
      verify: (c) => expect(
        (c.state as FeedLoaded).items.first.track.stats.likesCount,
        101,
      ),
    );

    blocTest<FeedCubit, FeedState>(
      'decrements likesCount when unliking',
      build: () {
        repo.feedPageToReturn = FeedPage(
          items: [makeItem(likes: 100, liked: true)],
          page: 1,
          hasMore: false,
          totalItems: 1,
        );
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        await c.handleLike('trk_001');
      },
      verify: (c) {
        final track = (c.state as FeedLoaded).items.first.track;
        expect(track.stats.likesCount, 99);
        expect(track.userState.liked, false);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'rolls back liked and count on API error',
      build: () {
        repo.feedPageToReturn = FeedPage(
          items: [makeItem(likes: 100, liked: false)],
          page: 1,
          hasMore: false,
          totalItems: 1,
        );
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        // Only toggleLike fails
        repo.toggleLikeError = Exception('API error');
        await c.handleLike('trk_001');
      },
      verify: (c) {
        final track = (c.state as FeedLoaded).items.first.track;
        expect(track.userState.liked, false); // rolled back
        expect(track.stats.likesCount, 100); // rolled back
      },
    );
  });

  // ─── handleRepost ──────────────────────────────────────────────────────────

  group('handleRepost', () {
    blocTest<FeedCubit, FeedState>(
      'optimistic repost update',
      build: () {
        repo.feedPageToReturn = FeedPage(
          items: [makeItem(reposts: 3, reposted: false)],
          page: 1,
          hasMore: false,
          totalItems: 1,
        );
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        await c.handleRepost('trk_001');
      },
      verify: (c) {
        final track = (c.state as FeedLoaded).items.first.track;
        expect(track.userState.reposted, true);
        expect(track.stats.repostsCount, 4);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'rollback repost on API failure',
      build: () {
        repo.feedPageToReturn = FeedPage(
          items: [makeItem(reposts: 3, reposted: false)],
          page: 1,
          hasMore: false,
          totalItems: 1,
        );
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        // Only toggleRepost fails
        repo.toggleRepostError = Exception('fail');
        await c.handleRepost('trk_001');
      },
      verify: (c) {
        final track = (c.state as FeedLoaded).items.first.track;
        expect(track.userState.reposted, false); // rolled back
        expect(track.stats.repostsCount, 3); // rolled back
      },
    );

    blocTest<FeedCubit, FeedState>(
      'removes repost when already reposted',
      build: () {
        repo.feedPageToReturn = FeedPage(
          items: [makeItem(reposts: 10, reposted: true)],
          page: 1,
          hasMore: false,
          totalItems: 1,
        );
        return buildCubit(repo);
      },
      act: (c) async {
        await c.initialize();
        await c.handleRepost('trk_001');
      },
      verify: (c) {
        final track = (c.state as FeedLoaded).items.first.track;
        expect(track.userState.reposted, false);
        expect(track.stats.repostsCount, 9);
      },
    );
  });

  // ─── handlePlay ────────────────────────────────────────────────────────────

  group('handlePlay', () {
    test('returns stream URL when playable', () async {
      repo.feedPageToReturn = makeFeedPage(count: 1);
      repo.streamUrlResult = 'https://cdn.com/audio.mp3';

      final cubit = buildCubit(repo);
      await cubit.initialize();
      final access = await cubit.handlePlay('trk_001');

      expect(access.streamUrl, 'https://cdn.com/audio.mp3');
      expect(access.accessState, 'PLAYABLE');
      cubit.close();
    });

    test('returns null when stream URL is null', () async {
      repo.feedPageToReturn = makeFeedPage(count: 1);
      repo.streamUrlResult = null;

      final cubit = buildCubit(repo);
      await cubit.initialize();
      final access = await cubit.handlePlay('trk_001');

      expect(access.streamUrl, isNull);
      expect(access.isBlocked, isTrue);
      cubit.close();
    });

    test('records play event', () async {
      repo.feedPageToReturn = makeFeedPage(count: 1);

      final cubit = buildCubit(repo);
      await cubit.initialize();
      await cubit.handlePlay('trk_001');

      expect(repo.playCalls.contains('trk_001'), true);
      cubit.close();
    });

    test('returns null when getStreamUrl throws', () async {
      repo.feedPageToReturn = makeFeedPage(count: 1);
      // Only streamUrl fails — getFeed still works
      repo.streamUrlError = Exception('Stream error');

      final cubit = buildCubit(repo);
      await cubit.initialize();
      final access = await cubit.handlePlay('trk_001');

      expect(access.streamUrl, isNull);
      expect(access.isBlocked, isTrue);
      cubit.close();
    });
  });

  // ─── FeedState equality ────────────────────────────────────────────────────

  group('FeedState equality (Equatable)', () {
    test('FeedLoading same tab are equal', () {
      expect(
        const FeedLoading(FeedTab.following),
        const FeedLoading(FeedTab.following),
      );
    });

    test('FeedLoading different tabs are not equal', () {
      expect(
        const FeedLoading(FeedTab.following),
        isNot(const FeedLoading(FeedTab.discover)),
      );
    });

    test('FeedEmpty same tab are equal', () {
      expect(
        const FeedEmpty(FeedTab.following),
        const FeedEmpty(FeedTab.following),
      );
    });

    test('FeedError same message are equal', () {
      expect(
        const FeedError(FeedTab.following, 'err'),
        const FeedError(FeedTab.following, 'err'),
      );
    });

    test('FeedLoaded copyWith different hasMore are not equal', () {
      final base = FeedLoaded(
        tab: FeedTab.following,
        items: [makeItem()],
        nextPage: 2,
        hasMore: true,
      );
      final updated = base.copyWith(hasMore: false);

      expect(base, isNot(updated));
      expect(updated.hasMore, false);
    });
  });

  // ─── FeedTab extension ─────────────────────────────────────────────────────

  group('FeedTab extension', () {
    test('key returns correct string', () {
      expect(FeedTab.following.key, 'following');
      expect(FeedTab.discover.key, 'discover');
    });

    test('label returns correct display string', () {
      expect(FeedTab.following.label, 'Following');
      expect(FeedTab.discover.label, 'Discover');
    });
  });
}
