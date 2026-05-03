import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedPage premium ad banner integration', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/feed/presentation/pages/feed_page.dart',
      ).readAsStringSync();
    });

    test('imports premium aware ad banner widget', () {
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/widgets/premium_aware_ad_banner.dart';",
        ),
      );
    });

    test('adds premium aware ad banner below the feed toggle', () {
      expect(
        source,
        contains('const SliverToBoxAdapter('),
      );
      expect(
        source,
        contains('child: PremiumAwareAdBanner('),
      );
      expect(
        source,
        contains("title: 'Enjoy the feed without ads'"),
      );
      expect(
        source,
        contains(
          "'Upgrade to remove sponsored cards, download tracks, and upload more music.'",
        ),
      );
      expect(
        source,
        contains("actionLabel: 'Upgrade'"),
      );
    });

    test('keeps the loaded feed in a sliver layout', () {
      expect(
        source,
        contains('CustomScrollView('),
      );
      expect(
        source,
        contains('SliverPersistentHeader('),
      );
      expect(
        source,
        contains('SliverList('),
      );
    });

    test('renders ad banner before feed cards', () {
      expect(
        source,
        contains('const SliverToBoxAdapter('),
      );
      expect(
        source,
        contains('child: PremiumAwareAdBanner('),
      );

      final banner = source.indexOf('child: PremiumAwareAdBanner(');
      final feedCards = source.indexOf('SliverList(');

      expect(banner, isNonNegative);
      expect(feedCards, isNonNegative);
      expect(feedCards, greaterThan(banner));
    });

    test('keeps footer after feed items', () {
      expect(
        source,
        contains('if (index == state.items.length)'),
      );
      expect(
        source,
        contains('return _Footer(state: state);'),
      );
    });

    test('uses direct feed item lookup in the sliver list', () {
      expect(
        source,
        contains('final item = state.items[index];'),
      );
    });

    test('keeps feed card behavior unchanged after index offset', () {
      expect(
        source,
        contains('FeedCard('),
      );
      expect(
        source,
        contains('key: ValueKey(item.activityId)'),
      );
      expect(
        source,
        contains('onLike: () => cubit.handleLike(item.track.trackId)'),
      );
      expect(
        source,
        contains('onRepost: () => cubit.handleRepost(item.track.trackId)'),
      );
      expect(
        source,
        contains('onPlay: () => _handlePlay('),
      );
    });

    test('keeps loaded feed refresh and infinite scroll behavior', () {
      expect(
        source,
        contains('NotificationListener<ScrollNotification>'),
      );
      expect(
        source,
        contains('cubit.loadMore();'),
      );
      expect(
        source,
        contains('RefreshIndicator('),
      );
      expect(
        source,
        contains('onRefresh: cubit.refresh'),
      );
    });
  });
}
