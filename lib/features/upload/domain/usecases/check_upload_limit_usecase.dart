import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';

class CheckUploadLimitUseCase {
  const CheckUploadLimitUseCase();

  bool call({
    required int remainingUploads,
    required bool isPro,
    bool isPremium = false,
    bool isUnlimited = false,
    int? uploadLimit,
    int? uploadedTracks,
    bool isActive = true,
    String planCode = '',
    String subscriptionStatus = '',
  }) {
    if (!_isSubscriptionActive(
      isActive: isActive,
      subscriptionStatus: subscriptionStatus,
    )) {
      return false;
    }

    if (_isUnlimitedPlan(
      isUnlimited: isUnlimited,
      uploadLimit: uploadLimit,
      planCode: planCode,
    )) {
      return true;
    }

    if (isPremium && !_isSubscriptionActive(
      isActive: isActive,
      subscriptionStatus: subscriptionStatus,
    )) {
      return false;
    }

    if (remainingUploads > 0) {
      return true;
    }

    if (uploadLimit != null && uploadedTracks != null) {
      return uploadedTracks < uploadLimit;
    }

    return false;
  }

  bool canUploadSubscription(Subscription subscription) {
    return call(
      remainingUploads: subscription.remainingUploads,
      isPro: subscription.isPro,
      isPremium: subscription.isPremium,
      isUnlimited: subscription.isUnlimited,
      uploadLimit: subscription.uploadLimit,
      uploadedTracks: subscription.uploadedTracks,
      isActive: subscription.isActive,
      planCode: subscription.planCode,
      subscriptionStatus: subscription.subscriptionStatus,
    );
  }

  String limitReachedMessage(Subscription subscription) {
    if (subscription.isPremium && !subscription.isActive) {
      return 'Your subscription is not active. Please update your billing status to upload.';
    }

    if (subscription.isPremium) {
      return 'Upload limit reached for ${subscription.displayPlanName}. You have used ${subscription.uploadedTracks}/${subscription.displayUploadLimit} uploads.';
    }

    return 'Upload limit reached. Upgrade to Pro to upload more tracks.';
  }

  bool _isSubscriptionActive({
    required bool isActive,
    required String subscriptionStatus,
  }) {
    if (subscriptionStatus.trim().isEmpty) {
      return isActive;
    }

    final normalizedStatus = subscriptionStatus.trim().toUpperCase();

    return normalizedStatus == 'ACTIVE' ||
        normalizedStatus == 'TRIALING' ||
        normalizedStatus == 'PAST_DUE';
  }

  bool _isUnlimitedPlan({
    required bool isUnlimited,
    required int? uploadLimit,
    required String planCode,
  }) {
    if (isUnlimited) {
      return true;
    }

    final normalizedPlanCode = planCode.trim().toUpperCase();

    if (normalizedPlanCode.contains('UNLIMITED')) {
      return true;
    }

    return uploadLimit != null && uploadLimit < 0;
  }
}
