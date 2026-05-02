import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryPage premium download entries', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/library/presentation/pages/library_page.dart',
      ).readAsStringSync();
    });

    test('imports subscription cubit and state', () {
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

    test('uses premium-aware downloaded tracks library item', () {
      expect(
        source,
        contains('const _PremiumDownloadLibraryItem('),
      );
      expect(
        source,
        contains("title: 'Downloaded tracks'"),
      );
      expect(
        source,
        contains("downloadsPath: '/library/downloads/tracks'"),
      );
      expect(
        source,
        contains('icon: Icons.download_for_offline_outlined'),
      );
    });

    test('uses premium-aware downloaded playlists library item', () {
      expect(
        source,
        contains("title: 'Downloaded playlists'"),
      );
      expect(
        source,
        contains("downloadsPath: '/library/downloads/playlists'"),
      );
      expect(
        source,
        contains('icon: Icons.queue_music'),
      );
    });

    test('defines premium download library item widget', () {
      expect(
        source,
        contains('class _PremiumDownloadLibraryItem extends StatelessWidget'),
      );
      expect(
        source,
        contains('final String title;'),
      );
      expect(
        source,
        contains('final String downloadsPath;'),
      );
      expect(
        source,
        contains('final IconData icon;'),
      );
    });

    test('reads subscription cubit from context or GetIt fallback', () {
      expect(
        source,
        contains('context.read<SubscriptionCubit>()'),
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

    test('builds item from subscription canDownload state', () {
      expect(
        source,
        contains('BlocBuilder<SubscriptionCubit, SubscriptionState>'),
      );
      expect(
        source,
        contains('canDownload: state.subscription.canDownload'),
      );
      expect(
        source,
        contains('isLoading: state.isInitial || state.isLoading'),
      );
    });

    test('shows available offline subtitle for premium downloads', () {
      expect(
        source,
        contains("'Available offline'"),
      );
    });

    test('shows premium required subtitle and badge for locked downloads', () {
      expect(
        source,
        contains("'Premium required for offline listening'"),
      );
      expect(
        source,
        contains("'Premium'"),
      );
      expect(
        source,
        isNot(contains('Icons.workspace_premium_rounded')),
      );    });

    test('shows loading indicator while subscription state is loading', () {
      expect(
        source,
        contains('CircularProgressIndicator('),
      );
      expect(
        source,
        contains('strokeWidth: 2'),
      );
    });

    test('routes premium users to downloaded content pages', () {
      expect(
        source,
        contains('context.push(downloadsPath);'),
      );
    });

    test('routes free users to upgrade page', () {
      expect(
        source,
        contains("context.go('/upgrade');"),
      );
    });

    test('disables tap while subscription state is loading', () {
      expect(
        source,
        contains('onTap: isLoading'),
      );
      expect(
        source,
        contains('? null'),
      );
    });

    test('falls back to available downloads when subscription cubit is absent', () {
      expect(
        source,
        contains('if (subscriptionCubit == null)'),
      );
      expect(
        source,
        contains('canDownload: true'),
      );
      expect(
        source,
        contains('isLoading: false'),
      );
    });
  });
}