import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UploadPickerPage premium upload quota card', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/upload/presentation/pages/upload_picker_page.dart',
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

    test('places upload quota card after user account card', () {
      expect(
        source,
        contains('_UserAccountCard(user: user)'),
      );
      expect(
        source,
        contains('const _UploadQuotaCard()'),
      );

      final accountCardIndex = source.indexOf('_UserAccountCard(user: user)');
      final quotaCardIndex = source.indexOf('const _UploadQuotaCard()');
      final selectAudioIndex = source.indexOf('ElevatedButton.icon(');

      expect(accountCardIndex, isNonNegative);
      expect(quotaCardIndex, isNonNegative);
      expect(selectAudioIndex, isNonNegative);
      expect(accountCardIndex, lessThan(quotaCardIndex));
      expect(quotaCardIndex, lessThan(selectAudioIndex));
    });

    test('defines upload quota card widget', () {
      expect(
        source,
        contains('class _UploadQuotaCard extends StatelessWidget'),
      );
      expect(
        source,
        contains('const _UploadQuotaCard();'),
      );
    });

    test('uses subscription state to render quota', () {
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
        contains('final isUnlimited = subscription.isUnlimited;'),
      );
      expect(
        source,
        contains('final remainingUploads = subscription.remainingUploads;'),
      );
    });

    test('shows loading quota state while subscription is loading', () {
      expect(
        source,
        contains('state.isInitial || state.isLoading'),
      );
      expect(
        source,
        contains("'Loading upload quota...'"),
      );
      expect(
        source,
        contains('CircularProgressIndicator(strokeWidth: 2)'),
      );
    });

    test('renders unlimited upload quota text', () {
      expect(
        source,
        contains("'Unlimited uploads'"),
      );
    });

    test('renders remaining uploads quota text', () {
      expect(
        source,
        contains(
          r"'${subscription.displayRemainingUploads} uploads remaining / ${subscription.displayUploadLimit}'",
        ),
      );
    });

    test('detects reached upload limit', () {
      expect(
        source,
        contains('final hasReachedLimit = !isUnlimited && remainingUploads <= 0;'),
      );
      expect(
        source,
        contains("'You reached your current upload limit. Upgrade to continue uploading tracks.'"),
      );
    });

    test('shows upgrade action when upload limit is reached', () {
      expect(
        source,
        contains('if (hasReachedLimit)'),
      );
      expect(
        source,
        contains("onPressed: () => context.go('/upgrade')"),
      );
      expect(
        source,
        contains('Icons.workspace_premium_rounded'),
      );
      expect(
        source,
        contains("'Upgrade to upload more'"),
      );
    });

    test('shows plan badge for premium and free users', () {
      expect(
        source,
        contains("subscription.isPremium ? 'Premium' : 'Free'"),
      );
    });

    test('shows premium and free explanatory messages', () {
      expect(
        source,
        contains("'Your premium plan gives you more room to publish music.'"),
      );
      expect(
        source,
        contains("'Free artists have a limited number of uploads.'"),
      );
    });

    test('keeps upload limit failure snackbar upgrade action', () {
      expect(
        source,
        contains('bool _isUploadLimitFailure(String message)'),
      );
      expect(
        source,
        contains("normalized.contains('upload limit reached')"),
      );
      expect(
        source,
        contains("SnackBarAction("),
      );
      expect(
        source,
        contains("label: 'Upgrade'"),
      );
      expect(
        source,
        contains("onPressed: () => context.go('/upgrade')"),
      );
    });

    test('refreshes subscription after successful upload', () {
      expect(
        source,
        contains('context.read<SubscriptionCubit>().refreshAfterPayment();'),
      );
    });

    test('keeps core upload actions after adding quota card', () {
      expect(
        source,
        contains("state.status == UploadPickerStatus.picking"),
      );
      expect(
        source,
        contains("'Select audio file'"),
      );
      expect(
        source,
        contains('cubit.uploadSelectedFile('),
      );
      expect(
        source,
        contains("'Upload Track'"),
      );
    });
  });
}