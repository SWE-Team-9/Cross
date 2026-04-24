import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Subscription> getMySubscription();
}
