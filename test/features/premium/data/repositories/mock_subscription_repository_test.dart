import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';

void main() {
  group('MockSubscriptionRepository', () {
    late MockSubscriptionRepository repository;

    setUp(() {
      repository = MockSubscriptionRepository();
    });

    test('starts with an active free subscription', () async {
      final subscription = await repository.getMySubscription();

      expect(subscription.userId, 'mock-user');
      expect(subscription.planCode, 'FREE');
      expect(subscription.subscriptionType, 'FREE');
      expect(subscription.subscriptionStatus, 'ACTIVE');
      expect(subscription.planName, 'Free');
      expect(subscription.isPremium, isFalse);
      expect(subscription.adsEnabled, isTrue);
      expect(subscription.canDownload, isFalse);
      expect(subscription.supportLevel, 'community');
      expect(subscription.uploadLimit, 3);
      expect(subscription.uploadLimitDisplay, '3');
      expect(subscription.uploadedTracks, 0);
      expect(subscription.remainingUploads, 3);
    });

    test('returns free pro and go plus plans', () async {
      final plans = await repository.getPlans();

      expect(plans, hasLength(3));

      expect(plans[0].code, 'FREE');
      expect(plans[0].name, 'Free');
      expect(plans[0].priceDisplay, 'Free');
      expect(plans[0].adsEnabled, isTrue);
      expect(plans[0].canDownload, isFalse);
      expect(plans[0].highlightedFeatures, contains('3 uploads'));

      expect(plans[1].code, 'PRO');
      expect(plans[1].name, 'Pro');
      expect(plans[1].priceDisplay, r'$9.99/mo');
      expect(plans[1].trialDays, 7);
      expect(plans[1].adsEnabled, isFalse);
      expect(plans[1].canDownload, isTrue);
      expect(plans[1].highlightedFeatures, contains('Offline downloads'));

      expect(plans[2].code, 'GO_PLUS');
      expect(plans[2].name, 'GO+');
      expect(plans[2].priceDisplay, r'$19.99/mo');
      expect(plans[2].uploadLimit, 1000);
      expect(plans[2].adsEnabled, isFalse);
      expect(plans[2].canDownload, isTrue);
    });

    test('createCheckout upgrades current subscription to pro', () async {
      final checkoutUrl = await repository.createCheckout('PRO');
      final subscription = await repository.getMySubscription();

      expect(checkoutUrl, 'https://mock-checkout.example.com/PRO');
      expect(subscription.planCode, 'PRO');
      expect(subscription.subscriptionType, 'PRO');
      expect(subscription.subscriptionStatus, 'ACTIVE');
      expect(subscription.planName, 'Pro');
      expect(subscription.isPremium, isTrue);
      expect(subscription.adsEnabled, isFalse);
      expect(subscription.canDownload, isTrue);
      expect(subscription.uploadLimit, 100);
      expect(subscription.remainingUploads, 100);
      expect(subscription.paymentMethodSummary, 'Visa •••• 4242');
    });

    test('createCheckout upgrades current subscription to go plus', () async {
      final checkoutUrl = await repository.createCheckout(' GO_PLUS ');
      final subscription = await repository.getMySubscription();

      expect(checkoutUrl, 'https://mock-checkout.example.com/GO_PLUS');
      expect(subscription.planCode, 'GO_PLUS');
      expect(subscription.subscriptionType, 'GO_PLUS');
      expect(subscription.planName, 'GO+');
      expect(subscription.isPremium, isTrue);
      expect(subscription.adsEnabled, isFalse);
      expect(subscription.canDownload, isTrue);
      expect(subscription.uploadLimit, 1000);
      expect(subscription.remainingUploads, 1000);
    });

    test('createCheckout returns empty url for free or empty plan', () async {
      expect(await repository.createCheckout('FREE'), '');
      expect((await repository.getMySubscription()).planCode, 'FREE');

      expect(await repository.createCheckout('   '), '');
      expect((await repository.getMySubscription()).planCode, 'FREE');
    });

    test('subscribe upgrades current subscription and returns subscribe url',
        () async {
      final subscribeUrl = await repository.subscribe('PRO');
      final subscription = await repository.getMySubscription();

      expect(subscribeUrl, 'https://mock-subscribe.example.com/PRO');
      expect(subscription.planCode, 'PRO');
      expect(subscription.isPremium, isTrue);
      expect(subscription.canDownload, isTrue);
    });

    test('subscribe returns empty url for free or empty plan', () async {
      expect(await repository.subscribe('FREE'), '');
      expect((await repository.getMySubscription()).planCode, 'FREE');

      expect(await repository.subscribe('   '), '');
      expect((await repository.getMySubscription()).planCode, 'FREE');
    });

    test(
        'openBillingPortalSession returns free portal capabilities for free plan',
        () async {
      final session = await repository.openBillingPortalSession();

      expect(session.url, 'https://mock-portal.example.com/session');
      expect(session.portalUrl, 'https://mock-portal.example.com');
      expect(session.sessionId, 'bps_mock_123');
      expect(session.customerId, 'cus_mock_123');
      expect(session.returnUrl, 'iqa3://billing/return');
      expect(session.paymentMethodSummary, '');
      expect(session.paymentMethod, isNull);
      expect(session.canUpdatePaymentMethod, isFalse);
      expect(session.canCancel, isFalse);
      expect(session.canResume, isFalse);
      expect(session.canChangePlan, isFalse);
      expect(session.launchUrl, 'https://mock-portal.example.com/session');
    });

    test(
        'openBillingPortalSession returns premium portal capabilities for premium plan',
        () async {
      await repository.createCheckout('PRO');

      final session = await repository.openBillingPortalSession();

      expect(session.paymentMethodSummary, 'Visa •••• 4242');
      expect(
        session.paymentMethod,
        <String, dynamic>{
          'brand': 'visa',
          'last4': '4242',
        },
      );
      expect(session.canUpdatePaymentMethod, isTrue);
      expect(session.canCancel, isTrue);
      expect(session.canResume, isFalse);
      expect(session.canChangePlan, isTrue);
    });

    test('openPortal returns billing portal launch url', () async {
      final portalUrl = await repository.openPortal();

      expect(portalUrl, 'https://mock-portal.example.com/session');
    });

    test('getInvoices returns empty invoices for free plan', () async {
      final invoices = await repository.getInvoices();

      expect(invoices, isEmpty);
    });

    test('getInvoices returns invoices for premium plan', () async {
      await repository.createCheckout('PRO');

      final invoices = await repository.getInvoices();

      expect(invoices, hasLength(1));
      expect(invoices.single.id, 'mock-invoice-1');
      expect(invoices.single.invoiceId, 'in_mock_abc123');
      expect(invoices.single.amountDueCents, 999);
      expect(invoices.single.amountPaidCents, 999);
      expect(invoices.single.currency, 'USD');
      expect(invoices.single.status, 'PAID');
      expect(invoices.single.planName, 'Pro');
      expect(invoices.single.planTier, 'PRO');
    });

    test('cancelSubscription does nothing for free plan', () async {
      final subscription = await repository.cancelSubscription();

      expect(subscription.planCode, 'FREE');
      expect(subscription.cancelAtPeriodEnd, isFalse);
      expect(subscription.canResume, isFalse);
    });

    test('cancelSubscription schedules cancellation for premium plan',
        () async {
      await repository.createCheckout('PRO');

      final subscription = await repository.cancelSubscription();

      expect(subscription.planCode, 'PRO');
      expect(subscription.isPremium, isTrue);
      expect(subscription.cancelAtPeriodEnd, isTrue);
      expect(subscription.canResume, isTrue);
      expect(subscription.subscriptionStatus, 'ACTIVE');

      final session = await repository.openBillingPortalSession();

      expect(session.canCancel, isFalse);
      expect(session.canResume, isTrue);
    });

    test('resumeSubscription does nothing for free plan', () async {
      final subscription = await repository.resumeSubscription();

      expect(subscription.planCode, 'FREE');
      expect(subscription.cancelAtPeriodEnd, isFalse);
      expect(subscription.canResume, isFalse);
    });

    test('resumeSubscription resumes premium cancellation', () async {
      await repository.createCheckout('PRO');
      await repository.cancelSubscription();

      final subscription = await repository.resumeSubscription();

      expect(subscription.planCode, 'PRO');
      expect(subscription.cancelAtPeriodEnd, isFalse);
      expect(subscription.canResume, isFalse);
      expect(subscription.subscriptionStatus, 'ACTIVE');
    });

    test('changePlan switches to go plus', () async {
      final subscription = await repository.changePlan('GO_PLUS');

      expect(subscription.planCode, 'GO_PLUS');
      expect(subscription.subscriptionType, 'GO_PLUS');
      expect(subscription.planName, 'GO+');
      expect(subscription.isPremium, isTrue);
      expect(subscription.uploadLimit, 1000);
      expect(subscription.remainingUploads, 1000);
    });

    test('changePlan switches back to free', () async {
      await repository.createCheckout('PRO');

      final subscription = await repository.changePlan('FREE');

      expect(subscription.planCode, 'FREE');
      expect(subscription.subscriptionType, 'FREE');
      expect(subscription.planName, 'Free');
      expect(subscription.isPremium, isFalse);
      expect(subscription.adsEnabled, isTrue);
      expect(subscription.canDownload, isFalse);
      expect(subscription.uploadLimit, 3);
      expect(subscription.remainingUploads, 3);
    });

    test('changePlan ignores empty plan', () async {
      await repository.createCheckout('PRO');

      final subscription = await repository.changePlan('   ');

      expect(subscription.planCode, 'PRO');
      expect(subscription.isPremium, isTrue);
    });

    test(
        'getOfflineTrackEntitlement returns free plan entitlement when current plan is free',
        () async {
      final entitlement = await repository.getOfflineTrackEntitlement(
        ' track-1 ',
      );

      expect(entitlement.trackId, 'track-1');
      expect(entitlement.title, 'Mock offline track');
      expect(entitlement.artist, 'IQA3 Artist');
      expect(entitlement.handle, 'iqa3artist');
      expect(entitlement.durationMs, 180000);
      expect(
        entitlement.coverArtUrl,
        'https://mock-media.example.com/covers/track-1.jpg',
      );
      expect(
        entitlement.downloadUrl,
        'https://mock-media.example.com/offline/track-1.mp3',
      );
      expect(entitlement.expiresAt, isNotNull);
      expect(entitlement.expiresInSeconds, 900);
      expect(entitlement.offlineTokenId, 'offline_mock_track-1');
      expect(entitlement.planCode, 'FREE');
      expect(entitlement.isAllowed, isFalse);
    });

    test('getOfflineTrackEntitlement returns premium entitlement after upgrade',
        () async {
      await repository.createCheckout('PRO');

      final entitlement = await repository.getOfflineTrackEntitlement(
        'track-1',
      );

      expect(entitlement.trackId, 'track-1');
      expect(entitlement.planCode, 'PRO');
      expect(entitlement.isAllowed, isTrue);
      expect(entitlement.isPro, isTrue);
      expect(entitlement.hasDownloadUrl, isTrue);
      expect(entitlement.hasOfflineToken, isTrue);
    });
  });
}
