import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';

void main() {
  group('profile constants', () {
    test('profileByHandlePath builds expected path', () {
      expect(
        ApiConstants.profileByHandlePath('ali'),
        '/api/v1/profiles/ali',
      );
    });
  });

  group('social constants', () {
    test('followersPath builds expected path', () {
      expect(
        ApiConstants.followersPath('u1'),
        '/api/v1/social/u1/followers',
      );
    });

    test('followingPath builds expected path', () {
      expect(
        ApiConstants.followingPath('u1'),
        '/api/v1/social/u1/following',
      );
    });

    test('followUserPath builds expected path', () {
      expect(
        ApiConstants.followUserPath('u1'),
        '/api/v1/social/follow/u1',
      );
    });

    test('blockUserPath builds expected path', () {
      expect(
        ApiConstants.blockUserPath('u1'),
        '/api/v1/social/block/u1',
      );
    });
  });

  group('subscription constants', () {
    test('uses the expected subscription base path', () {
      expect(
        ApiConstants.subscriptionsBase,
        '/api/v1/subscriptions',
      );
    });

    test('builds current subscription path', () {
      expect(
        ApiConstants.mySubscription,
        '/api/v1/subscriptions/me',
      );
    });

    test('builds subscription plans path', () {
      expect(
        ApiConstants.subscriptionPlans,
        '/api/v1/subscriptions/plans',
      );
    });

    test('builds subscription invoices path', () {
      expect(
        ApiConstants.subscriptionInvoices,
        '/api/v1/subscriptions/invoices',
      );
    });

    test('builds checkout path', () {
      expect(
        ApiConstants.subscriptionCheckout,
        '/api/v1/subscriptions/checkout',
      );
    });

    test('builds legacy subscribe path', () {
      expect(
        ApiConstants.subscriptionSubscribe,
        '/api/v1/subscriptions/subscribe',
      );
    });

    test('builds billing portal path', () {
      expect(
        ApiConstants.subscriptionPortal,
        '/api/v1/subscriptions/portal',
      );
    });

    test('builds resume subscription path', () {
      expect(
        ApiConstants.subscriptionResume,
        '/api/v1/subscriptions/resume',
      );
    });

    test('builds change plan path', () {
      expect(
        ApiConstants.subscriptionChangePlan,
        '/api/v1/subscriptions/change-plan',
      );
    });

    test('builds cancel subscription path', () {
      expect(
        ApiConstants.subscriptionCancel,
        '/api/v1/subscriptions/cancel',
      );
    });

    test('builds offline track entitlement path', () {
      expect(
        ApiConstants.subscriptionOfflineTrackPath('track-123'),
        '/api/v1/subscriptions/offline/track-123',
      );
    });

    test('builds offline track stream path', () {
      expect(
        ApiConstants.subscriptionOfflineTrackStreamPath('track-123'),
        '/api/v1/subscriptions/offline/track-123/stream',
      );
    });
  });
}