import '../entities/subscription.dart';
import '../entities/plan.dart';

abstract class SubscriptionRepository {
  Future<Subscription> getMySubscription();

  // NEW
  Future<String> createCheckout(String plan);

  Future<List<Plan>> getPlans();
  Future<void> cancelSubscription();
  Future<void> resumeSubscription();
  Future<void> changePlan(String plan);
  Future<String> openPortal();
}
