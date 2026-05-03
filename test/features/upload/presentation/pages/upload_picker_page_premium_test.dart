import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UploadPickerPage premium upload-limit UI', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/upload/presentation/pages/upload_picker_page.dart',
      ).readAsStringSync();
    });

    test('imports go_router for upgrade navigation', () {
      expect(
        source,
        contains("import 'package:go_router/go_router.dart';"),
      );
    });

    test('detects upload-limit failures in page listener', () {
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
        contains("normalized.contains('upgrade to pro')"),
      );
      expect(
        source,
        contains("normalized.contains('subscription is not active')"),
      );
      expect(
        source,
        contains("normalized.contains('billing status')"),
      );
    });

    test('adds upgrade snackbar action for upload-limit failures', () {
      expect(
        source,
        contains('final isUploadLimitFailure ='),
      );
      expect(
        source,
        contains('_isUploadLimitFailure(errorMessage);'),
      );
      expect(
        source,
        contains('action: isUploadLimitFailure'),
      );
      expect(
        source,
        contains('SnackBarAction('),
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

    test('keeps non-limit failures without upgrade action', () {
      expect(
        source,
        contains(': null,'),
      );
    });

    test('shows premium-specific upload status title for limit failures', () {
      expect(
        source,
        contains('final isLimitFailure = _isUploadLimitMessage(errorMessage);'),
      );
      expect(
        source,
        contains("? 'Upload limit reached'"),
      );
    });

    test('uses premium icon for upload-limit status card failures', () {
      expect(
        source,
        contains('Icons.workspace_premium_outlined'),
      );
      expect(
        source,
        contains('Theme.of(context).colorScheme.primary'),
      );
    });

    test('keeps generic error icon for normal upload failures', () {
      expect(
        source,
        contains('Icons.error_outline'),
      );
      expect(
        source,
        contains('Colors.redAccent'),
      );
    });

    test('detects upload-limit messages in status card helper', () {
      expect(
        source,
        contains('bool _isUploadLimitMessage(String message)'),
      );

      final helperStart = source.indexOf(
        'bool _isUploadLimitMessage(String message)',
      );

      expect(helperStart, isNonNegative);

      final helperSource = source.substring(helperStart);

      expect(
        helperSource,
        contains("normalized.contains('upload limit reached')"),
      );
      expect(
        helperSource,
        contains("normalized.contains('upgrade to pro')"),
      );
      expect(
        helperSource,
        contains("normalized.contains('subscription is not active')"),
      );
      expect(
        helperSource,
        contains("normalized.contains('billing status')"),
      );
    });

    test('keeps upload success subscription refresh behavior', () {
      expect(
        source,
        contains('context.read<SubscriptionCubit>().refreshAfterPayment();'),
      );
    });
  });
}
