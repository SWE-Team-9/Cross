import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackRow premium download gate', () {
    late String source;

    setUpAll(() {
      source = File('lib/core/widgets/track_row.dart').readAsStringSync();
    });

    test('imports subscription cubit and state for premium checks', () {
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

    test('hides download action while subscription is not ready', () {
      expect(
        source,
        contains('subscriptionState.isInitial || subscriptionState.isLoading'),
      );
      expect(
        source,
        contains('return const SizedBox.shrink();'),
      );
    });

    test('shows locked premium download button for free users', () {
      expect(
        source,
        contains('final canDownload = subscriptionState.subscription.canDownload;'),
      );
      expect(
        source,
        contains('if (!canDownload)'),
      );
      expect(
        source,
        contains('isLocked: true'),
      );
      expect(
        source,
        contains('_showDownloadSnackbar(context, _DownloadSnack.upgradeRequired)'),
      );
      expect(
        source,
        contains('_openUpgradePage(context);'),
      );
    });

    test('keeps offline cubit download flow for premium users', () {
      expect(
        source,
        contains('return BlocBuilder<OfflineCubit, OfflineState>('),
      );
      expect(
        source,
        contains('final isDownloaded = offlineCubit.isDownloaded(track.id);'),
      );
      expect(
        source,
        contains('await offlineCubit.downloadTrack(track);'),
      );
      expect(
        source,
        contains('_showDownloadSnackbar(context, _DownloadSnack.saved);'),
      );
    });

    test('keeps already downloaded feedback', () {
      expect(
        source,
        contains('if (isDownloaded)'),
      );
      expect(
        source,
        contains('_showDownloadSnackbar(context, _DownloadSnack.alreadySaved);'),
      );
    });

    test('keeps upgrade redirect for premium-required download errors', () {
      expect(
        source,
        contains('if (_isUpgradeRequired(error))'),
      );
      expect(
        source,
        contains('_DownloadSnack.upgradeRequired'),
      );
      expect(
        source,
        contains('context.push(\'/upgrade\');'),
      );
    });

    test('download button supports locked visual state', () {
      expect(
        source,
        contains('class _DownloadButton extends StatelessWidget'),
      );
      expect(
        source,
        contains('final bool isLocked;'),
      );
      expect(
        source,
        contains('this.isLocked = false'),
      );
      expect(
        source,
        contains('final isHighlighted = isDownloaded || isLocked;'),
      );
    });

    test('locked download button uses premium icon and tooltip', () {
      expect(
        source,
        contains("'Upgrade for offline downloads'"),
      );
      expect(
        source,
        contains('Icons.workspace_premium_rounded'),
      );
    });

    test('downloaded and normal download tooltips are preserved', () {
      expect(
        source,
        contains("'Downloaded'"),
      );
      expect(
        source,
        contains("'Download for offline listening'"),
      );
    });

    test('download button icons cover locked downloaded and available states', () {
      expect(
        source,
        contains('Icons.workspace_premium_rounded'),
      );
      expect(
        source,
        contains('Icons.download_done_rounded'),
      );
      expect(
        source,
        contains('Icons.arrow_downward_rounded'),
      );
    });

    test('download snackbar has upgrade required message', () {
      expect(
        source,
        contains("'Upgrade required for offline downloads'"),
      );
      expect(
        source,
        contains('_DownloadSnack.upgradeRequired'),
      );
    });

    test('does not remove playback and menu behavior', () {
      expect(
        source,
        contains('void openMenu(BuildContext context)'),
      );
      expect(
        source,
        contains('Future<void> _playTrack(BuildContext context) async'),
      );
      expect(
        source,
        contains('TrackOptionsSheet.show(context, track: track)'),
      );
    });
  });
}