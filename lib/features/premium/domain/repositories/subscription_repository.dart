import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Subscription> getMySubscription();

  Future<Subscription> subscribe(String plan);
}
