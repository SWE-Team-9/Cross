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

    test('adds premium aware ad banner as first loaded feed item', () {
      expect(
        source,
        contains('return const PremiumAwareAdBanner('),
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

    test('updates loaded feed item count for ad banner and footer', () {
      expect(
        source,
        contains('itemCount: state.items.length + 2'),
      );
      expect(
        source,
        contains('// +1 ad banner, +1 footer'),
      );
    });

    test('renders ad banner only at index zero', () {
      expect(
        source,
        contains('if (index == 0)'),
      );
      expect(
        source,
        contains('return const PremiumAwareAdBanner('),
      );

      final indexCheck = source.indexOf('if (index == 0)');
      final bannerReturn = source.indexOf('return const PremiumAwareAdBanner(');

      expect(indexCheck, isNonNegative);
      expect(bannerReturn, isNonNegative);
      expect(bannerReturn, greaterThan(indexCheck));
    });

    test('moves footer index after ad banner offset', () {
      expect(
        source,
        contains('if (index == state.items.length + 1)'),
      );
      expect(
        source,
        contains('return _Footer(state: state);'),
      );
    });

    test('uses index minus one for feed item lookup after banner', () {
      expect(
        source,
        contains('final item = state.items[index - 1];'),
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