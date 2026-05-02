import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackOptionsSheet premium download action', () {
    late String source;

    setUpAll(() {
      source = File('lib/core/widgets/track_options_sheet.dart').readAsStringSync();
    });

    test('imports go router for upgrade navigation', () {
      expect(
        source,
        contains("import 'package:go_router/go_router.dart';"),
      );
    });

    test('imports offline cubit and state', () {
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';",
        ),
      );
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';",
        ),
      );
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

    test('adds download option before add to playlist option', () {
      expect(
        source,
        contains('_DownloadOptionTile('),
      );
      expect(
        source,
        contains('track: track'),
      );
      expect(
        source,
        contains('parentContext: parentContext'),
      );

      final downloadIndex = source.indexOf('_DownloadOptionTile(');
      final addToPlaylistIndex = source.indexOf("label: 'Add to playlist'");

      expect(downloadIndex, isNonNegative);
      expect(addToPlaylistIndex, isNonNegative);
      expect(downloadIndex, lessThan(addToPlaylistIndex));
    });

    test('defines download option tile widget', () {
      expect(
        source,
        contains('class _DownloadOptionTile extends StatelessWidget'),
      );
      expect(
        source,
        contains('final Track track;'),
      );
      expect(
        source,
        contains('final BuildContext parentContext;'),
      );
    });

    test('looks up subscription and offline cubits from context or GetIt', () {
      expect(
        source,
        contains('final subscriptionCubit = _lookupCubit<SubscriptionCubit>(parentContext);'),
      );
      expect(
        source,
        contains('final offlineCubit = _lookupCubit<OfflineCubit>(parentContext);'),
      );
      expect(
        source,
        contains('context.read<T>()'),
      );
      expect(
        source,
        contains('getIt.isRegistered<T>()'),
      );
      expect(
        source,
        contains('return getIt<T>();'),
      );
    });

    test('hides download option when required cubits are unavailable', () {
      expect(
        source,
        contains('if (subscriptionCubit == null || offlineCubit == null)'),
      );
      expect(
        source,
        contains('return const SizedBox.shrink();'),
      );
    });

    test('hides download option while subscription state is loading', () {
      expect(
        source,
        contains('subscriptionState.isInitial || subscriptionState.isLoading'),
      );
    });

    test('shows premium required option for free users', () {
      expect(
        source,
        contains('if (!subscriptionState.subscription.canDownload)'),
      );
      expect(
        source,
        contains('Icons.workspace_premium_rounded'),
      );
      expect(
        source,
        contains("label: 'Download requires Premium'"),
      );
      expect(
        source,
        contains("'Upgrade required for offline downloads'"),
      );
      expect(
        source,
        contains('_openUpgradePage(parentContext);'),
      );
    });

    test('shows offline download option for premium users', () {
      expect(
        source,
        contains('BlocBuilder<OfflineCubit, OfflineState>'),
      );
      expect(
        source,
        contains('final isDownloaded = offlineCubit.isDownloaded(track.id);'),
      );
      expect(
        source,
        contains('Icons.download_for_offline_outlined'),
      );
      expect(
        source,
        contains("label: isDownloaded"),
      );
      expect(
        source,
        contains("'Download for offline'"),
      );
    });

    test('shows downloaded state when track is already saved', () {
      expect(
        source,
        contains('Icons.download_done_rounded'),
      );
      expect(
        source,
        contains("'Downloaded for offline'"),
      );
      expect(
        source,
        contains("Music already downloaded"),
      );
    });

    test('downloads track through offline cubit', () {
      expect(
        source,
        contains('await offlineCubit.downloadTrack(track);'),
      );
      expect(
        source,
        contains("'Saved for offline listening'"),
      );
    });

    test('handles premium-required download errors by opening upgrade', () {
      expect(
        source,
        contains('if (_isUpgradeRequired(error))'),
      );
      expect(
        source,
        contains("text.contains('UPGRADE_REQUIRED')"),
      );
      expect(
        source,
        contains("text.contains('PREMIUM')"),
      );
      expect(
        source,
        contains("text.contains('SUBSCRIPTION')"),
      );
      expect(
        source,
        contains("text.contains('403')"),
      );
      expect(
        source,
        contains("text.contains('401')"),
      );
      expect(
        source,
        contains('_openUpgradePage(parentContext);'),
      );
    });

    test('shows normal download failure snackbar', () {
      expect(
        source,
        contains("'Download failed'"),
      );
      expect(
        source,
        contains('isError: true'),
      );
    });

    test('opens upgrade route from parent context', () {
      expect(
        source,
        contains("context.push('/upgrade');"),
      );
    });

    test('keeps existing track option actions intact', () {
      expect(
        source,
        contains("label: 'Like'"),
      );
      expect(
        source,
        contains("label: 'Play Next'"),
      );
      expect(
        source,
        contains("label: 'Play Last'"),
      );
      expect(
        source,
        contains("label: 'Add to playlist'"),
      );
      expect(
        source,
        contains("label: 'Repost'"),
      );
      expect(
        source,
        contains("label: 'Go to artist profile'"),
      );
      expect(
        source,
        contains("label: 'View comments'"),
      );
    });
  });
}