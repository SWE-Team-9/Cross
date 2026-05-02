import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_parser.dart';

void main() {
  group('DeepLinkParser', () {
    test('rejects unknown scheme', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('https://track/track-1'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Unknown scheme: expected soundclone://',
      );
    });

    test('rejects unknown host', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://unknown/path'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect((destination as InvalidDeepLink).reason, 'Unknown host: unknown');
    });

    test('parses track deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://track/track-1'),
      );

      expect(destination, isA<TrackDeepLink>());
      expect((destination as TrackDeepLink).trackId, 'track-1');
    });

    test('rejects track link without id', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://track'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect((destination as InvalidDeepLink).reason, 'Track link missing ID');
    });

    test('parses secret track deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://track/secret/secret-token'),
      );

      expect(destination, isA<SecretTrackDeepLink>());
      expect(
        (destination as SecretTrackDeepLink).secretToken,
        'secret-token',
      );
    });

    test('rejects secret track link without token', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://track/secret'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Secret track link missing token',
      );
    });

    test('parses profile deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://user/ali'),
      );

      expect(destination, isA<ProfileDeepLink>());
      expect((destination as ProfileDeepLink).handle, 'ali');
    });

    test('rejects user link without handle', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://user'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect((destination as InvalidDeepLink).reason, 'User link missing handle');
    });

    test('parses playlist deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://playlist/playlist-1'),
      );

      expect(destination, isA<PlaylistDeepLink>());
      expect((destination as PlaylistDeepLink).playlistId, 'playlist-1');
    });

    test('parses secret playlist deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://playlist/secret/secret-playlist'),
      );

      expect(destination, isA<SecretPlaylistDeepLink>());
      expect(
        (destination as SecretPlaylistDeepLink).secretToken,
        'secret-playlist',
      );
    });

    test('rejects playlist link without id', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://playlist'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Playlist link missing ID',
      );
    });

    test('rejects secret playlist link without token', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://playlist/secret'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Secret playlist link missing token',
      );
    });

    test('parses search deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://search?q=lofi%20beats'),
      );

      expect(destination, isA<SearchDeepLink>());
      expect((destination as SearchDeepLink).query, 'lofi beats');
    });

    test('rejects search link without query', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://search?q=%20%20'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Search link missing query',
      );
    });

    test('parses oauth success callback', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://oauth/callback?code=code-123&state=abc'),
      );

      expect(destination, isA<OAuthCallbackDeepLink>());

      final oauthDestination = destination as OAuthCallbackDeepLink;

      expect(oauthDestination.code, 'code-123');
      expect(oauthDestination.state, 'abc');
      expect(oauthDestination.hasError, isFalse);
    });

    test('parses oauth error callback', () {
      final destination = DeepLinkParser.parse(
        Uri.parse(
          'soundclone://oauth/callback?error=access_denied&error_description=Denied',
        ),
      );

      expect(destination, isA<OAuthCallbackDeepLink>());

      final oauthDestination = destination as OAuthCallbackDeepLink;

      expect(oauthDestination.error, 'access_denied');
      expect(oauthDestination.errorDescription, 'Denied');
      expect(oauthDestination.hasError, isTrue);
    });

    test('rejects oauth callback without code', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://oauth/callback'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'OAuth callback missing authorization code',
      );
    });

    test('rejects oauth link with invalid path', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://oauth/authorize'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'OAuth link must be soundclone://oauth/callback',
      );
    });

    test('parses billing return deep link with snake case params', () {
      final destination = DeepLinkParser.parse(
        Uri.parse(
          'soundclone://billing/return'
          '?session_id=bps_123'
          '&customer_id=cus_123'
          '&status=success'
          '&plan_code=PRO'
          '&checkout_session_id=cs_123'
          '&subscription_id=sub_123',
        ),
      );

      expect(destination, isA<BillingReturnDeepLink>());

      final billingDestination = destination as BillingReturnDeepLink;

      expect(billingDestination.sessionId, 'bps_123');
      expect(billingDestination.customerId, 'cus_123');
      expect(billingDestination.status, 'success');
      expect(billingDestination.planCode, 'PRO');
      expect(billingDestination.checkoutSessionId, 'cs_123');
      expect(billingDestination.subscriptionId, 'sub_123');
      expect(billingDestination.hasSuccessStatus, isTrue);
      expect(billingDestination.hasSessionReference, isTrue);
    });

    test('parses billing return deep link with camel case params', () {
      final destination = DeepLinkParser.parse(
        Uri.parse(
          'soundclone://billing/return'
          '?billingSessionId=bps_456'
          '&customerId=cus_456'
          '&paymentStatus=completed'
          '&planCode=GO_PLUS'
          '&checkoutSessionId=cs_456'
          '&subscriptionId=sub_456',
        ),
      );

      expect(destination, isA<BillingReturnDeepLink>());

      final billingDestination = destination as BillingReturnDeepLink;

      expect(billingDestination.sessionId, 'bps_456');
      expect(billingDestination.customerId, 'cus_456');
      expect(billingDestination.status, 'completed');
      expect(billingDestination.planCode, 'GO_PLUS');
      expect(billingDestination.checkoutSessionId, 'cs_456');
      expect(billingDestination.subscriptionId, 'sub_456');
      expect(billingDestination.hasSuccessStatus, isTrue);
    });

    test('parses billing return cancellation status', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://billing/return?status=cancelled'),
      );

      expect(destination, isA<BillingReturnDeepLink>());
      expect((destination as BillingReturnDeepLink).hasCancelStatus, isTrue);
    });

    test('rejects billing link with invalid path', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://billing/session'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Billing link must be soundclone://billing/return',
      );
    });

    test('parses checkout return deep link', () {
      final destination = DeepLinkParser.parse(
        Uri.parse(
          'soundclone://checkout/return'
          '?cs=cs_789'
          '&sub=sub_789'
          '&tier=PRO'
          '&billingStatus=active',
        ),
      );

      expect(destination, isA<BillingReturnDeepLink>());

      final billingDestination = destination as BillingReturnDeepLink;

      expect(billingDestination.checkoutSessionId, 'cs_789');
      expect(billingDestination.subscriptionId, 'sub_789');
      expect(billingDestination.planCode, 'PRO');
      expect(billingDestination.status, 'active');
      expect(billingDestination.hasSuccessStatus, isTrue);
    });

    test('rejects checkout link with invalid path', () {
      final destination = DeepLinkParser.parse(
        Uri.parse('soundclone://checkout/session'),
      );

      expect(destination, isA<InvalidDeepLink>());
      expect(
        (destination as InvalidDeepLink).reason,
        'Checkout link must be soundclone://checkout/return',
      );
    });
  });
}