import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';

void main() {
  group('BillingReturnDeepLink', () {
    test('stores billing return identifiers', () {
      const destination = BillingReturnDeepLink(
        sessionId: 'bps_123',
        customerId: 'cus_123',
        status: 'success',
        planCode: 'PRO',
        checkoutSessionId: 'cs_123',
        subscriptionId: 'sub_123',
      );

      expect(destination.sessionId, 'bps_123');
      expect(destination.customerId, 'cus_123');
      expect(destination.status, 'success');
      expect(destination.planCode, 'PRO');
      expect(destination.checkoutSessionId, 'cs_123');
      expect(destination.subscriptionId, 'sub_123');
    });

    test('hasSuccessStatus returns true for successful billing statuses', () {
      const successStatuses = <String>[
        'SUCCESS',
        'success',
        ' completed ',
        'PAID',
        'active',
      ];

      for (final status in successStatuses) {
        expect(
          BillingReturnDeepLink(status: status).hasSuccessStatus,
          isTrue,
          reason: '$status should be treated as successful',
        );
      }
    });

    test('hasSuccessStatus returns false for non-success statuses', () {
      const nonSuccessStatuses = <String?>[
        null,
        '',
        'pending',
        'failed',
        'cancel',
        'cancelled',
      ];

      for (final status in nonSuccessStatuses) {
        expect(
          BillingReturnDeepLink(status: status).hasSuccessStatus,
          isFalse,
          reason: '$status should not be treated as successful',
        );
      }
    });

    test('hasCancelStatus returns true for canceled billing statuses', () {
      const cancelStatuses = <String>[
        'CANCEL',
        'cancel',
        ' canceled ',
        'CANCELLED',
        'cancelled',
      ];

      for (final status in cancelStatuses) {
        expect(
          BillingReturnDeepLink(status: status).hasCancelStatus,
          isTrue,
          reason: '$status should be treated as canceled',
        );
      }
    });

    test('hasCancelStatus returns false for non-cancel statuses', () {
      const nonCancelStatuses = <String?>[
        null,
        '',
        'success',
        'completed',
        'paid',
        'active',
        'failed',
      ];

      for (final status in nonCancelStatuses) {
        expect(
          BillingReturnDeepLink(status: status).hasCancelStatus,
          isFalse,
          reason: '$status should not be treated as canceled',
        );
      }
    });

    test('hasSessionReference returns true when session id is present', () {
      const destination = BillingReturnDeepLink(
        sessionId: 'bps_123',
      );

      expect(destination.hasSessionReference, isTrue);
    });

    test('hasSessionReference returns true when checkout session id is present',
        () {
      const destination = BillingReturnDeepLink(
        checkoutSessionId: 'cs_123',
      );

      expect(destination.hasSessionReference, isTrue);
    });

    test('hasSessionReference returns true when subscription id is present',
        () {
      const destination = BillingReturnDeepLink(
        subscriptionId: 'sub_123',
      );

      expect(destination.hasSessionReference, isTrue);
    });

    test('hasSessionReference returns false when all references are empty', () {
      const destination = BillingReturnDeepLink(
        sessionId: '   ',
        checkoutSessionId: '',
        subscriptionId: null,
      );

      expect(destination.hasSessionReference, isFalse);
    });
  });

  group('existing deep link destinations', () {
    test('track destination stores track id', () {
      const destination = TrackDeepLink(trackId: 'track-1');

      expect(destination.trackId, 'track-1');
    });

    test('secret track destination stores token', () {
      const destination = SecretTrackDeepLink(secretToken: 'secret-track');

      expect(destination.secretToken, 'secret-track');
    });

    test('profile destination stores handle', () {
      const destination = ProfileDeepLink(handle: 'ali');

      expect(destination.handle, 'ali');
    });

    test('playlist destination stores playlist id', () {
      const destination = PlaylistDeepLink(playlistId: 'playlist-1');

      expect(destination.playlistId, 'playlist-1');
    });

    test('secret playlist destination stores token', () {
      const destination = SecretPlaylistDeepLink(
        secretToken: 'secret-playlist',
      );

      expect(destination.secretToken, 'secret-playlist');
    });

    test('search destination stores query', () {
      const destination = SearchDeepLink(query: 'lofi');

      expect(destination.query, 'lofi');
    });

    test('oauth callback detects error state', () {
      const errorDestination = OAuthCallbackDeepLink(
        error: 'access_denied',
      );

      const successDestination = OAuthCallbackDeepLink(
        code: 'code-123',
      );

      expect(errorDestination.hasError, isTrue);
      expect(successDestination.hasError, isFalse);
    });

    test('invalid destination stores reason', () {
      const destination = InvalidDeepLink(reason: 'Unknown host');

      expect(destination.reason, 'Unknown host');
    });
  });
}
