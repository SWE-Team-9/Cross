import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidManifest premium billing deep links', () {
    late String manifest;

    setUpAll(() {
      manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
    });

    test('keeps oauth callback intent filter registered', () {
      expect(
        manifest,
        contains('<!-- OAuth callback -->'),
      );
      expect(
        manifest,
        contains('android:host="oauth"'),
      );
      expect(
        manifest,
        contains('android:pathPrefix="/callback"'),
      );
    });

    test('registers billing portal return intent filter', () {
      expect(
        manifest,
        contains('<!-- Billing portal return -->'),
      );
      expect(
        manifest,
        contains('android:host="billing"'),
      );
      expect(
        manifest,
        contains('android:pathPrefix="/return"'),
      );
    });

    test('registers checkout return intent filter', () {
      expect(
        manifest,
        contains('<!-- Checkout return -->'),
      );
      expect(
        manifest,
        contains('android:host="checkout"'),
      );
      expect(
        manifest,
        contains('android:pathPrefix="/return"'),
      );
    });

    test('all billing deep links use soundclone custom scheme', () {
      final soundcloneSchemeMatches = RegExp(
        r'android:scheme="soundclone"',
      ).allMatches(manifest);

      expect(soundcloneSchemeMatches.length, greaterThanOrEqualTo(3));
    });

    test('billing return filters are browsable and default', () {
      final billingFilterStart = manifest.indexOf('<!-- Billing portal return -->');
      final checkoutFilterStart = manifest.indexOf('<!-- Checkout return -->');

      expect(billingFilterStart, isNonNegative);
      expect(checkoutFilterStart, isNonNegative);
      expect(billingFilterStart, lessThan(checkoutFilterStart));

      final billingFilter = manifest.substring(
        billingFilterStart,
        checkoutFilterStart,
      );
      final checkoutFilter = manifest.substring(checkoutFilterStart);

      for (final filter in <String>[billingFilter, checkoutFilter]) {
        expect(
          filter,
          contains('android.intent.action.VIEW'),
        );
        expect(
          filter,
          contains('android.intent.category.BROWSABLE'),
        );
        expect(
          filter,
          contains('android.intent.category.DEFAULT'),
        );
      }
    });

    test('billing filters are placed inside MainActivity', () {
      final mainActivityStart = manifest.indexOf('android:name=".MainActivity"');
      final activityEnd = manifest.indexOf('</activity>', mainActivityStart);
      final billingFilterStart = manifest.indexOf('<!-- Billing portal return -->');
      final checkoutFilterStart = manifest.indexOf('<!-- Checkout return -->');

      expect(mainActivityStart, isNonNegative);
      expect(activityEnd, isNonNegative);
      expect(billingFilterStart, isNonNegative);
      expect(checkoutFilterStart, isNonNegative);

      expect(billingFilterStart, greaterThan(mainActivityStart));
      expect(billingFilterStart, lessThan(activityEnd));
      expect(checkoutFilterStart, greaterThan(mainActivityStart));
      expect(checkoutFilterStart, lessThan(activityEnd));
    });

    test('deep links are available on exported single task main activity', () {
      final mainActivityStart = manifest.indexOf('android:name=".MainActivity"');
      final activityEnd = manifest.indexOf('</activity>', mainActivityStart);
      final mainActivity = manifest.substring(mainActivityStart, activityEnd);

      expect(
        mainActivity,
        contains('android:exported="true"'),
      );
      expect(
        mainActivity,
        contains('android:launchMode="singleTask"'),
      );
    });
  });
}