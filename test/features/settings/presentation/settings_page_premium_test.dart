import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsPage premium settings entry', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/settings/presentation/page/settings_page.dart',
      ).readAsStringSync();
    });

    test('imports GetIt and subscription bloc dependencies', () {
      expect(
        source,
        contains("import 'package:get_it/get_it.dart';"),
      );
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';",
        ),
      );
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';",
        ),
      );
    });

    test('adds premium section after account section', () {
      expect(
        source,
        contains("// ── Premium ───────────────────────────────────────────────────"),
      );
      expect(
        source,
        contains("_SectionHeader(title: 'Premium')"),
      );
      expect(
        source,
        contains('const _SubscriptionSettingsTile()'),
      );

      final accountIndex = source.indexOf("// ── Account");
      final premiumIndex = source.indexOf("// ── Premium");
      final privacyIndex = source.indexOf("// ── Privacy");

      expect(accountIndex, isNonNegative);
      expect(premiumIndex, isNonNegative);
      expect(privacyIndex, isNonNegative);
      expect(accountIndex, lessThan(premiumIndex));
      expect(premiumIndex, lessThan(privacyIndex));
    });

    test('defines subscription settings tile widget', () {
      expect(
        source,
        contains('class _SubscriptionSettingsTile extends StatelessWidget'),
      );
      expect(
        source,
        contains('const _SubscriptionSettingsTile();'),
      );
    });

    test('reads subscription cubit from context or GetIt fallback', () {
      expect(
        source,
        contains('context.read<SubscriptionCubit>()'),
      );
      expect(
        source,
        contains('GetIt.I'),
      );
      expect(
        source,
        contains('getIt.isRegistered<SubscriptionCubit>()'),
      );
      expect(
        source,
        contains('getIt<SubscriptionCubit>()'),
      );
    });

    test('falls back to upgrade entry when subscription cubit is unavailable', () {
      expect(
        source,
        contains('if (cubit == null)'),
      );
      expect(
        source,
        contains("title: 'IQA3 Premium'"),
      );
      expect(
        source,
        contains("subtitle: 'Manage your plan and billing'"),
      );
      expect(
        source,
        contains('icon: Icons.workspace_premium_outlined'),
      );
      expect(
        source,
        contains("onTap: () => context.go('/upgrade')"),
      );
    });

    test('uses BlocBuilder for subscription-aware settings state', () {
      expect(
        source,
        contains('BlocBuilder<SubscriptionCubit, SubscriptionState>'),
      );
      expect(
        source,
        contains('final subscription = state.subscription;'),
      );
      expect(
        source,
        contains('final isPremium = subscription.isPremium;'),
      );
    });

    test('shows premium plan title and billing route for premium users', () {
      expect(
        source,
        contains("'${subscription.displayPlanName} plan'"),
      );
      expect(
        source,
        contains("'Manage billing, invoices, and premium features'"),
      );
      expect(
        source,
        contains('Icons.workspace_premium_rounded'),
      );
      expect(
        source,
        contains("context.go(isPremium ? '/billing' : '/upgrade')"),
      );
    });

    test('shows upgrade title and upgrade route for free users', () {
      expect(
        source,
        contains("'IQA3 Premium'"),
      );
      expect(
        source,
        contains("'Upgrade for ad-free listening and offline downloads'"),
      );
      expect(
        source,
        contains('Icons.workspace_premium_outlined'),
      );
      expect(
        source,
        contains("'/upgrade'"),
      );
    });

    test('reuses shared settings tile styling', () {
      expect(
        source,
        contains('return _SettingsTile('),
      );
      expect(
        source,
        contains('icon: icon'),
      );
      expect(
        source,
        contains('title: title'),
      );
      expect(
        source,
        contains('subtitle: subtitle'),
      );
      expect(
        source,
        contains('onTap: onTap'),
      );
    });

    test('keeps existing privacy and account settings sections', () {
      expect(
        source,
        contains("_SectionHeader(title: 'Account')"),
      );
      expect(
        source,
        contains("_SectionHeader(title: 'Privacy')"),
      );
      expect(
        source,
        contains("_SectionHeader(title: 'Notifications')"),
      );
      expect(
        source,
        contains("_SectionHeader(title: 'About')"),
      );
    });
  });
}