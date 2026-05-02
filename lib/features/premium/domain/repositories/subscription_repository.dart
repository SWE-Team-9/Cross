import '../entities/subscription.dart';
import '../entities/plan.dart';

/// Minimal abstract repository kept to preserve the public API.
abstract class SubscriptionRepository {
  Future<Subscription> getMySubscription();

  Future<String> createCheckout(String plan);

  Future<List<Plan>> getPlans();
  Future<void> cancelSubscription();
  Future<void> resumeSubscription();
  Future<void> changePlan(String plan);
  Future<String> openPortal();
}
