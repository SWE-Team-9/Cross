import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockSearchPage premium ad integration', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/search/presentation/pages/mock_search_page.dart',
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

    test('renders premium aware ad banner above search results', () {
      expect(
        source,
        contains('const PremiumAwareAdBanner('),
      );
      expect(
        source,
        contains("title: 'Search and listen without ads'"),
      );
      expect(
        source,
        contains(
          "'Upgrade to remove sponsored cards, save music offline, and unlock more uploads.'",
        ),
      );
      expect(
        source,
        contains("actionLabel: 'Upgrade'"),
      );
    });

    test('wraps search body in column with banner before expanded content', () {
      final columnIndex = source.indexOf('body: Column(');
      final bannerIndex = source.indexOf('const PremiumAwareAdBanner(');
      final expandedIndex = source.indexOf('Expanded(');

      expect(columnIndex, isNonNegative);
      expect(bannerIndex, isNonNegative);
      expect(expandedIndex, isNonNegative);
      expect(columnIndex, lessThan(bannerIndex));
      expect(bannerIndex, lessThan(expandedIndex));
    });

    test('keeps empty search state message', () {
      expect(
        source,
        contains("'Start typing to search'"),
      );
    });

    test('keeps search results rendered with track row queue', () {
      expect(
        source,
        contains('ListView.builder('),
      );
      expect(
        source,
        contains('itemCount: _results.length'),
      );
      expect(
        source,
        contains('TrackRow('),
      );
      expect(
        source,
        contains('track: track'),
      );
      expect(
        source,
        contains('queue: _results'),
      );
      expect(
        source,
        contains("source: 'search'"),
      );
    });

    test('clears results when query is empty', () {
      expect(
        source,
        contains('final normalizedQuery = query.trim().toLowerCase();'),
      );
      expect(
        source,
        contains('normalizedQuery.isEmpty'),
      );
      expect(
        source,
        contains('? <Track>[]'),
      );
    });

    test('filters search results by title and artist', () {
      expect(
        source,
        contains('track.title.toLowerCase().contains(normalizedQuery)'),
      );
      expect(
        source,
        contains('track.artist.toLowerCase().contains(normalizedQuery)'),
      );
    });

    test('disposes search text controller', () {
      expect(
        source,
        contains('void dispose()'),
      );
      expect(
        source,
        contains('_controller.dispose();'),
      );
      expect(
        source,
        contains('super.dispose();'),
      );
    });

    test('keeps bottom navigation routes including upgrade', () {
      expect(
        source,
        contains("context.goNamed('home')"),
      );
      expect(
        source,
        contains("context.goNamed('feed')"),
      );
      expect(
        source,
        contains("context.goNamed('library')"),
      );
      expect(
        source,
        contains("context.goNamed('upgrade')"),
      );
    });

    test('keeps mock search tracks available for local search', () {
      expect(
        source,
        contains('final List<Track> _mockTracks = ['),
      );
      expect(
        source,
        contains("title: 'Feed Track 1'"),
      );
      expect(
        source,
        contains("title: 'Chill Vibes'"),
      );
      expect(
        source,
        contains("title: 'Workout Mix'"),
      );
    });
  });
}