import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryPage premium ad integration', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/library/presentation/pages/library_page.dart',
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

    test('renders premium aware ad banner in library content', () {
      expect(
        source,
        contains('const PremiumAwareAdBanner('),
      );
      expect(
        source,
        contains("title: 'Take your library offline'"),
      );
      expect(
        source,
        contains(
          "'Upgrade to remove sponsored cards, download music, and unlock more uploads.'",
        ),
      );
      expect(
        source,
        contains("actionLabel: 'Upgrade'"),
      );
    });

    test('places premium ad after top spacing and before library items', () {
      final spacerIndex = source.indexOf('const SizedBox(height: 12)');
      final bannerIndex = source.indexOf('const PremiumAwareAdBanner(');
      final likesItemIndex = source.indexOf("title: 'Your likes'");

      expect(spacerIndex, isNonNegative);
      expect(bannerIndex, isNonNegative);
      expect(likesItemIndex, isNonNegative);
      expect(spacerIndex, lessThan(bannerIndex));
      expect(bannerIndex, lessThan(likesItemIndex));
    });

    test('keeps premium download library item integration', () {
      expect(
        source,
        contains('class _PremiumDownloadLibraryItem extends StatelessWidget'),
      );
      expect(
        source,
        contains("title: 'Downloaded tracks'"),
      );
      expect(
        source,
        contains("title: 'Downloaded playlists'"),
      );
      expect(
        source,
        contains('canDownload: state.subscription.canDownload'),
      );
    });

    test('keeps locked download entries routed to upgrade', () {
      expect(
        source,
        contains("'Premium required for offline listening'"),
      );
      expect(
        source,
        contains("context.go('/upgrade');"),
      );
    });

    test('keeps available download entries routed to downloads pages', () {
      expect(
        source,
        contains("downloadsPath: '/library/downloads/tracks'"),
      );
      expect(
        source,
        contains("downloadsPath: '/library/downloads/playlists'"),
      );
      expect(
        source,
        contains('context.push(downloadsPath);'),
      );
    });

    test('keeps bottom navigation selected on library tab', () {
      expect(
        source,
        contains('bottomNavigationBar: const BottomNavBar(selected: 3)'),
      );
    });

    test('keeps library core sections after premium banner', () {
      expect(source, contains("title: 'Your likes'"));
      expect(source, contains("title: 'Playlists'"));
      expect(source, contains("title: 'Your uploads'"));
      expect(source, contains("title: 'Liked playlists'"));
      expect(source, contains("title: 'Recently played playlists'"));
    });
  });
}
