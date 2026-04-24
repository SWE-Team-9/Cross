import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<Subscription> getMySubscription() async {
    // Simulate FREE user who reached limit
    return const Subscription(
      subscriptionType: 'FREE',
      uploadLimit: 3,
      uploadedTracks: 2,
      remainingUploads: 1,
    );
  }
}
