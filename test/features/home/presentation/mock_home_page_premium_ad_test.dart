import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockHomePage premium ad banner integration', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/home/presentation/pages/mock_home_page.dart',
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

    test('renders premium aware ad banner in home scroll content', () {
      expect(
        source,
        contains('const PremiumAwareAdBanner('),
      );
      expect(
        source,
        contains("title: 'Ad-free listening is one tap away'"),
      );
      expect(
        source,
        contains(
          "'Go Premium to remove sponsored cards, save music offline, and unlock more uploads.'",
        ),
      );
      expect(
        source,
        contains("actionLabel: 'Upgrade'"),
      );
    });

    test('places premium ad before home recommendation sections', () {
      final bannerIndex = source.indexOf('const PremiumAwareAdBanner(');
      final moreLikeIndex = source.indexOf(
        "const _SectionHeader(title: 'More of what you like')",
      );
      final relatedTracksIndex = source.indexOf('const _RelatedTracksRow()');

      expect(bannerIndex, isNonNegative);
      expect(moreLikeIndex, isNonNegative);
      expect(relatedTracksIndex, isNonNegative);
      expect(bannerIndex, lessThan(moreLikeIndex));
      expect(moreLikeIndex, lessThan(relatedTracksIndex));
    });

    test('keeps subscription badge integration on top bar', () {
      expect(
        source,
        contains('class _SubscriptionBadge extends StatelessWidget'),
      );
      expect(
        source,
        contains('BlocBuilder<SubscriptionCubit, SubscriptionState>'),
      );
      expect(
        source,
        contains('subscription.normalizedPlanCode'),
      );
      expect(
        source,
        contains('subscription.isPremium'),
      );
    });

    test('keeps free badge navigation to upgrade route', () {
      expect(
        source,
        contains("badgeLabel = 'GET PRO'"),
      );
      expect(
        source,
        contains("onTap: isPremium ? null : () => context.go('/upgrade')"),
      );
    });

    test('keeps premium badge labels for pro and go plus users', () {
      expect(
        source,
        contains("badgeLabel = 'PRO'"),
      );
      expect(
        source,
        contains("badgeLabel = 'GO+'"),
      );
    });
  });
}
