import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';

void main() {
  group('Subscription', () {
    test('uses free defaults safely', () {
      const subscription = Subscription();

      expect(subscription.userId, '');
      expect(subscription.planCode, 'FREE');
      expect(subscription.subscriptionType, 'FREE');
      expect(subscription.subscriptionStatus, 'INACTIVE');
      expect(subscription.planName, 'Free');
      expect(subscription.isPremium, isFalse);
      expect(subscription.adsEnabled, isTrue);
      expect(subscription.canDownload, isFalse);
      expect(subscription.supportLevel, 'community');
      expect(subscription.uploadLimit, 3);
      expect(subscription.uploadLimitDisplay, '3');
      expect(subscription.isUnlimited, isFalse);
      expect(subscription.uploadedTracks, 0);
      expect(subscription.remainingUploads, 3);
      expect(subscription.cancelAtPeriodEnd, isFalse);
      expect(subscription.canResume, isFalse);

      expect(subscription.isFree, isTrue);
      expect(subscription.isPro, isFalse);
      expect(subscription.isActive, isFalse);
      expect(subscription.canUpload, isFalse);
      expect(subscription.shouldShowAds, isTrue);
      expect(subscription.shouldShowUpgradePrompt, isTrue);
      expect(subscription.displayPlanName, 'Free');
      expect(subscription.displayUploadLimit, '3');
      expect(subscription.displayRemainingUploads, '3');
      expect(subscription.uploadUsageRatio, 0);
    });

    test('fromJson parses active Pro subscription from swagger response shape',
        () {
      final subscription = Subscription.fromJson(
        const <String, dynamic>{
          'userId': 'user-uuid-1',
          'planCode': 'PRO',
          'subscriptionType': 'PRO',
          'subscriptionStatus': 'ACTIVE',
          'planName': 'Pro',
          'isPremium': true,
          'adsEnabled': false,
          'canDownload': true,
          'supportLevel': 'priority',
          'uploadLimit': 100,
          'uploadLimitDisplay': '100',
          'uploadedTracks': 5,
          'remainingUploads': 95,
          'currentPeriodEnd': '2026-05-01T00:00:00.000Z',
          'renewalDate': '2026-05-01T00:00:00.000Z',
          'expiresAt': null,
          'cancelAtPeriodEnd': false,
          'canResume': false,
          'resumeBlockedReason': null,
          'resumeBlockedMessage': null,
          'trialStart': null,
          'trialEnd': null,
          'paymentMethodSummary': 'Visa •••• 4242',
          'paymentMethod': <String, dynamic>{
            'brand': 'visa',
            'last4': '4242',
          },
          'pendingDowngrade': null,
          'latestInvoice': <String, dynamic>{
            'id': 'billing-invoice-uuid',
            'status': 'PAID',
          },
        },
      );

      expect(subscription.userId, 'user-uuid-1');
      expect(subscription.planCode, 'PRO');
      expect(subscription.subscriptionType, 'PRO');
      expect(subscription.subscriptionStatus, 'ACTIVE');
      expect(subscription.planName, 'Pro');
      expect(subscription.isPremium, isTrue);
      expect(subscription.adsEnabled, isFalse);
      expect(subscription.canDownload, isTrue);
      expect(subscription.supportLevel, 'priority');
      expect(subscription.uploadLimit, 100);
      expect(subscription.uploadLimitDisplay, '100');
      expect(subscription.uploadedTracks, 5);
      expect(subscription.remainingUploads, 95);
      expect(subscription.currentPeriodEnd,
          DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(
          subscription.renewalDate, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(subscription.expiresAt, isNull);
      expect(subscription.cancelAtPeriodEnd, isFalse);
      expect(subscription.canResume, isFalse);
      expect(subscription.paymentMethodSummary, 'Visa •••• 4242');
      expect(
        subscription.paymentMethod,
        <String, dynamic>{
          'brand': 'visa',
          'last4': '4242',
        },
      );
      expect(
        subscription.latestInvoice,
        <String, dynamic>{
          'id': 'billing-invoice-uuid',
          'status': 'PAID',
        },
      );

      expect(subscription.isFree, isFalse);
      expect(subscription.isPro, isTrue);
      expect(subscription.isProPlan, isTrue);
      expect(subscription.isGoPlus, isFalse);
      expect(subscription.isActive, isTrue);
      expect(subscription.canUpload, isTrue);
      expect(subscription.shouldShowAds, isFalse);
      expect(subscription.shouldShowUpgradePrompt, isFalse);
      expect(subscription.displayPlanName, 'Pro');
      expect(subscription.displayUploadLimit, '100');
      expect(subscription.displayRemainingUploads, '95');
      expect(subscription.uploadUsageRatio, 0.05);
      expect(subscription.nextBillingDate,
          DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(subscription.hasPaymentMethod, isTrue);
      expect(subscription.hasLatestInvoice, isTrue);
      expect(subscription.hasPendingDowngrade, isFalse);
    });

    test('fromJson accepts snake case keys from alternate backend serializers',
        () {
      final subscription = Subscription.fromJson(
        const <String, dynamic>{
          'user_id': 'user-uuid-2',
          'plan_code': 'GO_PLUS',
          'subscription_type': 'GO_PLUS',
          'subscription_status': 'ACTIVE',
          'plan_name': 'GO+',
          'is_premium': true,
          'ads_enabled': false,
          'can_download': true,
          'support_level': 'priority',
          'upload_limit': 1000,
          'upload_limit_display': '1000',
          'uploaded_tracks': 50,
          'remaining_uploads': 950,
          'current_period_end': '2026-06-01T00:00:00.000Z',
          'renewal_date': '2026-06-01T00:00:00.000Z',
          'expires_at': null,
          'cancel_at_period_end': true,
          'can_resume': true,
          'resume_blocked_reason': null,
          'resume_blocked_message': null,
          'trial_start': '2026-05-01T00:00:00.000Z',
          'trial_end': '2026-05-08T00:00:00.000Z',
          'payment_method_summary': 'Mastercard •••• 1111',
          'payment_method': <String, dynamic>{
            'brand': 'mastercard',
            'last4': '1111',
          },
          'pending_downgrade': <String, dynamic>{
            'planCode': 'PRO',
          },
          'latest_invoice': <String, dynamic>{
            'status': 'PAID',
          },
        },
      );

      expect(subscription.userId, 'user-uuid-2');
      expect(subscription.planCode, 'GO_PLUS');
      expect(subscription.subscriptionType, 'GO_PLUS');
      expect(subscription.subscriptionStatus, 'ACTIVE');
      expect(subscription.planName, 'GO+');
      expect(subscription.isPremium, isTrue);
      expect(subscription.adsEnabled, isFalse);
      expect(subscription.canDownload, isTrue);
      expect(subscription.supportLevel, 'priority');
      expect(subscription.uploadLimit, 1000);
      expect(subscription.uploadLimitDisplay, '1000');
      expect(subscription.uploadedTracks, 50);
      expect(subscription.remainingUploads, 950);
      expect(subscription.cancelAtPeriodEnd, isTrue);
      expect(subscription.canResume, isTrue);
      expect(subscription.paymentMethodSummary, 'Mastercard •••• 1111');
      expect(subscription.isGoPlus, isTrue);
      expect(subscription.hasPendingDowngrade, isTrue);
    });

    test('infers premium values when explicit isPremium is missing', () {
      final subscription = Subscription.fromJson(
        const <String, dynamic>{
          'planCode': 'PRO',
          'subscriptionType': 'PRO',
          'subscriptionStatus': 'ACTIVE',
        },
      );

      expect(subscription.isPremium, isTrue);
      expect(subscription.adsEnabled, isFalse);
      expect(subscription.supportLevel, 'priority');
      expect(subscription.uploadLimit, 100);
      expect(subscription.remainingUploads, 100);
      expect(subscription.displayPlanName, 'Pro');
    });

    test('falls back to free values when json is empty', () {
      final subscription = Subscription.fromJson(const <String, dynamic>{});

      expect(subscription.planCode, 'FREE');
      expect(subscription.subscriptionType, 'FREE');
      expect(subscription.subscriptionStatus, 'INACTIVE');
      expect(subscription.planName, 'Free');
      expect(subscription.isPremium, isFalse);
      expect(subscription.adsEnabled, isTrue);
      expect(subscription.uploadLimit, 3);
      expect(subscription.remainingUploads, 3);
    });

    test('supports unlimited upload display and ratio', () {
      final subscription = Subscription.fromJson(
        const <String, dynamic>{
          'planCode': 'PRO',
          'subscriptionType': 'PRO',
          'subscriptionStatus': 'ACTIVE',
          'isPremium': true,
          'isUnlimited': true,
          'uploadLimit': 0,
          'uploadLimitDisplay': '',
          'uploadedTracks': 500,
          'remainingUploads': 0,
        },
      );

      expect(subscription.isUnlimited, isTrue);
      expect(subscription.displayUploadLimit, 'Unlimited');
      expect(subscription.displayRemainingUploads, 'Unlimited');
      expect(subscription.hasRemainingUploads, isTrue);
      expect(subscription.canUpload, isTrue);
      expect(subscription.uploadUsageRatio, 0);
    });

    test('clamps negative remaining uploads to zero', () {
      final subscription = Subscription.fromJson(
        const <String, dynamic>{
          'uploadLimit': 3,
          'uploadedTracks': 5,
          'remainingUploads': -2,
        },
      );

      expect(subscription.remainingUploads, 0);
      expect(subscription.hasRemainingUploads, isFalse);
    });

    test('clamps upload usage ratio between zero and one', () {
      const subscription = Subscription(
        uploadLimit: 3,
        uploadedTracks: 10,
        remainingUploads: 0,
      );

      expect(subscription.uploadUsageRatio, 1);
    });

    test('supports canceled and trialing status helpers', () {
      final trialing = Subscription.fromJson(
        const <String, dynamic>{
          'subscriptionStatus': 'TRIALING',
        },
      );

      final canceled = Subscription.fromJson(
        const <String, dynamic>{
          'subscriptionStatus': 'CANCELED',
        },
      );

      expect(trialing.isActive, isTrue);
      expect(trialing.isTrialing, isTrue);
      expect(canceled.isCanceled, isTrue);
    });

    test('toJson serializes all fields', () {
      final subscription = Subscription(
        userId: 'user-uuid-1',
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        planName: 'Pro',
        isPremium: true,
        adsEnabled: false,
        canDownload: true,
        supportLevel: 'priority',
        uploadLimit: 100,
        uploadLimitDisplay: '100',
        isUnlimited: false,
        uploadedTracks: 5,
        remainingUploads: 95,
        currentPeriodEnd: DateTime.parse('2026-05-01T00:00:00.000Z'),
        renewalDate: DateTime.parse('2026-05-01T00:00:00.000Z'),
        expiresAt: DateTime.parse('2026-07-01T00:00:00.000Z'),
        cancelAtPeriodEnd: true,
        canResume: true,
        resumeBlockedReason: 'already_expired',
        resumeBlockedMessage: 'Subscription already expired.',
        trialStart: DateTime.parse('2026-04-01T00:00:00.000Z'),
        trialEnd: DateTime.parse('2026-04-08T00:00:00.000Z'),
        paymentMethodSummary: 'Visa •••• 4242',
        paymentMethod: const <String, dynamic>{
          'brand': 'visa',
          'last4': '4242',
        },
        pendingDowngrade: const <String, dynamic>{
          'planCode': 'FREE',
        },
        latestInvoice: const <String, dynamic>{
          'status': 'PAID',
        },
      );

      expect(
        subscription.toJson(),
        <String, dynamic>{
          'userId': 'user-uuid-1',
          'planCode': 'PRO',
          'subscriptionType': 'PRO',
          'subscriptionStatus': 'ACTIVE',
          'planName': 'Pro',
          'isPremium': true,
          'adsEnabled': false,
          'canDownload': true,
          'supportLevel': 'priority',
          'uploadLimit': 100,
          'uploadLimitDisplay': '100',
          'isUnlimited': false,
          'uploadedTracks': 5,
          'remainingUploads': 95,
          'currentPeriodEnd': '2026-05-01T00:00:00.000Z',
          'renewalDate': '2026-05-01T00:00:00.000Z',
          'expiresAt': '2026-07-01T00:00:00.000Z',
          'cancelAtPeriodEnd': true,
          'canResume': true,
          'resumeBlockedReason': 'already_expired',
          'resumeBlockedMessage': 'Subscription already expired.',
          'trialStart': '2026-04-01T00:00:00.000Z',
          'trialEnd': '2026-04-08T00:00:00.000Z',
          'paymentMethodSummary': 'Visa •••• 4242',
          'paymentMethod': <String, dynamic>{
            'brand': 'visa',
            'last4': '4242',
          },
          'pendingDowngrade': <String, dynamic>{
            'planCode': 'FREE',
          },
          'latestInvoice': <String, dynamic>{
            'status': 'PAID',
          },
        },
      );
    });

    test('copyWith updates selected fields only', () {
      const original = Subscription(
        userId: 'user-uuid-1',
        planCode: 'FREE',
        subscriptionType: 'FREE',
        subscriptionStatus: 'INACTIVE',
        uploadLimit: 3,
        remainingUploads: 3,
      );

      final updated = original.copyWith(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        adsEnabled: false,
        canDownload: true,
        uploadLimit: 100,
        remainingUploads: 100,
      );

      expect(updated.userId, 'user-uuid-1');
      expect(updated.planCode, 'PRO');
      expect(updated.subscriptionType, 'PRO');
      expect(updated.subscriptionStatus, 'ACTIVE');
      expect(updated.isPremium, isTrue);
      expect(updated.adsEnabled, isFalse);
      expect(updated.canDownload, isTrue);
      expect(updated.uploadLimit, 100);
      expect(updated.remainingUploads, 100);
    });

    test('copyWith clears nullable fields', () {
      final original = Subscription(
        currentPeriodEnd: DateTime.parse('2026-05-01T00:00:00.000Z'),
        renewalDate: DateTime.parse('2026-05-01T00:00:00.000Z'),
        expiresAt: DateTime.parse('2026-07-01T00:00:00.000Z'),
        resumeBlockedReason: 'blocked',
        resumeBlockedMessage: 'Blocked',
        trialStart: DateTime.parse('2026-04-01T00:00:00.000Z'),
        trialEnd: DateTime.parse('2026-04-08T00:00:00.000Z'),
        paymentMethodSummary: 'Visa •••• 4242',
        paymentMethod: const <String, dynamic>{'brand': 'visa'},
        pendingDowngrade: const <String, dynamic>{'planCode': 'FREE'},
        latestInvoice: const <String, dynamic>{'status': 'PAID'},
      );

      final updated = original.copyWith(
        clearCurrentPeriodEnd: true,
        clearRenewalDate: true,
        clearExpiresAt: true,
        clearResumeBlockedReason: true,
        clearResumeBlockedMessage: true,
        clearTrialStart: true,
        clearTrialEnd: true,
        clearPaymentMethodSummary: true,
        clearPaymentMethod: true,
        clearPendingDowngrade: true,
        clearLatestInvoice: true,
      );

      expect(updated.currentPeriodEnd, isNull);
      expect(updated.renewalDate, isNull);
      expect(updated.expiresAt, isNull);
      expect(updated.resumeBlockedReason, isNull);
      expect(updated.resumeBlockedMessage, isNull);
      expect(updated.trialStart, isNull);
      expect(updated.trialEnd, isNull);
      expect(updated.paymentMethodSummary, isNull);
      expect(updated.paymentMethod, isNull);
      expect(updated.pendingDowngrade, isNull);
      expect(updated.latestInvoice, isNull);
    });

    test('compares value equality including nested maps', () {
      const first = Subscription(
        planCode: 'PRO',
        paymentMethod: <String, dynamic>{
          'card': <String, dynamic>{
            'brand': 'visa',
            'last4': '4242',
          },
        },
      );

      const second = Subscription(
        planCode: 'PRO',
        paymentMethod: <String, dynamic>{
          'card': <String, dynamic>{
            'brand': 'visa',
            'last4': '4242',
          },
        },
      );

      const third = Subscription(
        planCode: 'PRO',
        paymentMethod: <String, dynamic>{
          'card': <String, dynamic>{
            'brand': 'visa',
            'last4': '1111',
          },
        },
      );

      expect(first, second);
      expect(first == third, isFalse);
      expect(first.hashCode, second.hashCode);
    });
  });
}
