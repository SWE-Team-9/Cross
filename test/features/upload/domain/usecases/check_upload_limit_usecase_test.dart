import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/check_upload_limit_usecase.dart';

void main() {
  group('CheckUploadLimitUseCase', () {
    late CheckUploadLimitUseCase useCase;

    setUp(() {
      useCase = const CheckUploadLimitUseCase();
    });

    test('allows upload when remaining uploads are available', () {
      final canUpload = useCase(
        remainingUploads: 2,
        isPro: false,
      );

      expect(canUpload, isTrue);
    });

    test('blocks upload when no remaining uploads are available', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: false,
      );

      expect(canUpload, isFalse);
    });

    test('does not allow pro flag alone when no quota remains', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
      );

      expect(canUpload, isFalse);
    });

    test('allows upload when uploaded tracks are below upload limit', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
        uploadLimit: 100,
        uploadedTracks: 99,
      );

      expect(canUpload, isTrue);
    });

    test('blocks upload when uploaded tracks equal upload limit', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
        uploadLimit: 100,
        uploadedTracks: 100,
      );

      expect(canUpload, isFalse);
    });

    test('blocks upload when uploaded tracks exceed upload limit', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
        uploadLimit: 100,
        uploadedTracks: 101,
      );

      expect(canUpload, isFalse);
    });

    test('allows upload for explicit unlimited plan flag', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
        isUnlimited: true,
        uploadLimit: 0,
        uploadedTracks: 500,
      );

      expect(canUpload, isTrue);
    });

    test('allows upload for negative upload limit as unlimited sentinel', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
        uploadLimit: -1,
        uploadedTracks: 999,
      );

      expect(canUpload, isTrue);
    });

    test('allows upload when plan code contains unlimited', () {
      final canUpload = useCase(
        remainingUploads: 0,
        isPro: true,
        uploadLimit: 0,
        uploadedTracks: 999,
        planCode: 'PRO_UNLIMITED',
      );

      expect(canUpload, isTrue);
    });

    test('blocks upload when isActive is false and status is empty', () {
      final canUpload = useCase(
        remainingUploads: 10,
        isPro: true,
        isActive: false,
      );

      expect(canUpload, isFalse);
    });

    test('allows active subscription status even when isActive is false', () {
      final canUpload = useCase(
        remainingUploads: 10,
        isPro: true,
        isActive: false,
        subscriptionStatus: 'ACTIVE',
      );

      expect(canUpload, isTrue);
    });

    test('allows trialing subscription status', () {
      final canUpload = useCase(
        remainingUploads: 10,
        isPro: true,
        isActive: false,
        subscriptionStatus: 'TRIALING',
      );

      expect(canUpload, isTrue);
    });

    test('allows past due subscription status', () {
      final canUpload = useCase(
        remainingUploads: 10,
        isPro: true,
        isActive: false,
        subscriptionStatus: 'PAST_DUE',
      );

      expect(canUpload, isTrue);
    });

    test('blocks canceled subscription status even when remaining uploads exist', () {
      final canUpload = useCase(
        remainingUploads: 10,
        isPro: true,
        isActive: true,
        subscriptionStatus: 'CANCELED',
      );

      expect(canUpload, isFalse);
    });

    test('blocks inactive subscription status even when remaining uploads exist', () {
      final canUpload = useCase(
        remainingUploads: 10,
        isPro: true,
        isActive: true,
        subscriptionStatus: 'INACTIVE',
      );

      expect(canUpload, isFalse);
    });

    test('canUploadSubscription allows active free user with remaining uploads', () {
      const subscription = Subscription(
        planCode: 'FREE',
        subscriptionType: 'FREE',
        subscriptionStatus: 'ACTIVE',
        isPremium: false,
        uploadLimit: 3,
        uploadedTracks: 1,
        remainingUploads: 2,
      );

      final canUpload = useCase.canUploadSubscription(subscription);

      expect(canUpload, isTrue);
    });

    test('canUploadSubscription blocks free user with exhausted limit', () {
      const subscription = Subscription(
        planCode: 'FREE',
        subscriptionType: 'FREE',
        subscriptionStatus: 'ACTIVE',
        isPremium: false,
        uploadLimit: 3,
        uploadedTracks: 3,
        remainingUploads: 0,
      );

      final canUpload = useCase.canUploadSubscription(subscription);

      expect(canUpload, isFalse);
    });

    test('canUploadSubscription allows premium user with remaining uploads', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 20,
        remainingUploads: 80,
      );

      final canUpload = useCase.canUploadSubscription(subscription);

      expect(canUpload, isTrue);
    });

    test('canUploadSubscription blocks premium user with exhausted finite limit', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 100,
        remainingUploads: 0,
      );

      final canUpload = useCase.canUploadSubscription(subscription);

      expect(canUpload, isFalse);
    });

    test('canUploadSubscription allows unlimited premium subscription', () {
      const subscription = Subscription(
        planCode: 'GO_PLUS',
        subscriptionType: 'GO_PLUS',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        isUnlimited: true,
        uploadLimit: 0,
        uploadedTracks: 1000,
        remainingUploads: 0,
      );

      final canUpload = useCase.canUploadSubscription(subscription);

      expect(canUpload, isTrue);
    });

    test('canUploadSubscription blocks inactive subscription', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'INACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 10,
        remainingUploads: 90,
      );

      final canUpload = useCase.canUploadSubscription(subscription);

      expect(canUpload, isFalse);
    });

    test('limitReachedMessage returns inactive billing message', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'INACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadLimitDisplay: '100',
        uploadedTracks: 10,
        remainingUploads: 90,
      );

      final message = useCase.limitReachedMessage(subscription);

      expect(
        message,
        'Your subscription is not active. Please update your billing status to upload.',
      );
    });

    test('limitReachedMessage returns premium quota message', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        planName: 'Pro',
        isPremium: true,
        uploadLimit: 100,
        uploadLimitDisplay: '100',
        uploadedTracks: 100,
        remainingUploads: 0,
      );

      final message = useCase.limitReachedMessage(subscription);

      expect(
        message,
        'Upload limit reached for Pro. You have used 100/100 uploads.',
      );
    });

    test('limitReachedMessage returns free upgrade message', () {
      const subscription = Subscription(
        planCode: 'FREE',
        subscriptionType: 'FREE',
        subscriptionStatus: 'ACTIVE',
        isPremium: false,
        uploadLimit: 3,
        uploadedTracks: 3,
        remainingUploads: 0,
      );

      final message = useCase.limitReachedMessage(subscription);

      expect(
        message,
        'Upload limit reached. Upgrade to Pro to upload more tracks.',
      );
    });
  });
}