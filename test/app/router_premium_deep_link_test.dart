import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('router billing return deep links', () {
    late String source;

    setUpAll(() {
      source = File('lib/app/router.dart')
          .readAsStringSync()
          .replaceAll('\r\n', '\n');
    });

    test('defines billing return path builder', () {
      expect(
        source,
        contains(
            'String _billingReturnPath(BillingReturnDeepLink destination)'),
      );
      expect(
        source,
        contains('final queryParameters = <String, String>{'),
      );
      expect(
        source,
        contains('path: AppRoutes.billing'),
      );
      expect(
        source,
        contains('return uri.toString();'),
      );
    });

    test('keeps billing return query parameters when present', () {
      expect(
        source,
        contains("'status': destination.status!.trim()"),
      );
      expect(
        source,
        contains("'plan': destination.planCode!.trim()"),
      );
      expect(
        source,
        contains("'session_id': destination.sessionId!.trim()"),
      );
      expect(
        source,
        contains(
          "'checkout_session_id': destination.checkoutSessionId!.trim()",
        ),
      );
      expect(
        source,
        contains("'subscription_id': destination.subscriptionId!.trim()"),
      );
    });

    test('omits empty billing return query parameters', () {
      expect(
        source,
        contains(
            'destination.status != null && destination.status!.trim().isNotEmpty'),
      );
      expect(
        source,
        contains(
            'destination.planCode != null && destination.planCode!.trim().isNotEmpty'),
      );
      expect(
        source,
        contains('destination.sessionId != null &&'),
      );
      expect(
        source,
        contains('destination.sessionId!.trim().isNotEmpty'),
      );
      expect(
        source,
        contains(
          'destination.checkoutSessionId != null &&\n        destination.checkoutSessionId!.trim().isNotEmpty',
        ),
      );
      expect(
        source,
        contains(
          'destination.subscriptionId != null &&\n        destination.subscriptionId!.trim().isNotEmpty',
        ),
      );
      expect(
        source,
        contains(
            'queryParameters: queryParameters.isEmpty ? null : queryParameters'),
      );
    });

    test('handles BillingReturnDeepLink in deep link switch', () {
      expect(
        source,
        contains('case BillingReturnDeepLink():'),
      );
      expect(
        source,
        contains('path = _billingReturnPath(destination);'),
      );

      final searchCaseIndex =
          source.indexOf('case SearchDeepLink(:final query):');
      final billingCaseIndex = source.indexOf('case BillingReturnDeepLink():');
      final oauthCaseIndex = source.indexOf('case OAuthCallbackDeepLink():');

      expect(searchCaseIndex, isNonNegative);
      expect(billingCaseIndex, isNonNegative);
      expect(oauthCaseIndex, isNonNegative);
      expect(searchCaseIndex, lessThan(billingCaseIndex));
      expect(billingCaseIndex, lessThan(oauthCaseIndex));
    });

    test(
        'routes billing return deep links through normal pending deep link flow',
        () {
      expect(
        source,
        contains('if (isOnAuthScreen) {'),
      );
      expect(
        source,
        contains('_pendingDeepLink = path;'),
      );
      expect(
        source,
        contains('router.go(path);'),
      );
    });

    test('keeps billing route registered', () {
      expect(
        source,
        contains("static const String billing = '/billing';"),
      );
      expect(
        source,
        contains('path: AppRoutes.billing'),
      );
      expect(
        source,
        contains("name: 'billing'"),
      );
      expect(
        source,
        contains('child: BillingPage()'),
      );
    });

    test('keeps upgrade and billing premium imports', () {
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/pages/billing_page.dart';",
        ),
      );
      expect(
        source,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';",
        ),
      );
    });

    test('keeps existing deep link routing intact', () {
      expect(
        source,
        contains('case TrackDeepLink(:final trackId):'),
      );
      expect(
        source,
        contains('case SecretTrackDeepLink(:final secretToken):'),
      );
      expect(
        source,
        contains('case ProfileDeepLink(:final handle):'),
      );
      expect(
        source,
        contains('case PlaylistDeepLink(:final playlistId):'),
      );
      expect(
        source,
        contains('case SecretPlaylistDeepLink(:final secretToken):'),
      );
      expect(
        source,
        contains('case SearchDeepLink(:final query):'),
      );
      expect(
        source,
        contains('case OAuthCallbackDeepLink():'),
      );
      expect(
        source,
        contains('case InvalidDeepLink():'),
      );
    });
  });
}
