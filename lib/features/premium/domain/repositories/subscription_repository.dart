import '../entities/billing_invoice.dart';
import '../entities/billing_portal_session.dart';
import '../entities/offline_track_entitlement.dart';
import '../entities/plan.dart';
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Subscription> getMySubscription();

  Future<List<Plan>> getPlans();

  Future<String> createCheckout(String plan);

  Future<String> subscribe(String plan);

  Future<BillingPortalSession> openBillingPortalSession();

  Future<List<BillingInvoice>> getInvoices();

  Future<Subscription> cancelSubscription();

  Future<Subscription> resumeSubscription();

  Future<Subscription> changePlan(String plan);

  Future<Subscription> cancelPlanChange();

  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(String trackId);

  /// Legacy compatibility for existing callers.
  Future<String> openPortal() async {
    final session = await openBillingPortalSession();
    return session.launchUrl;
  }
}
