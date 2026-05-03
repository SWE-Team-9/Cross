import '../entities/billing_invoice.dart';
import '../entities/billing_portal_session.dart';
import '../entities/offline_track_entitlement.dart';
import '../entities/plan.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class GetMySubscriptionUseCase {
  const GetMySubscriptionUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<Subscription> call() {
    return _repository.getMySubscription();
  }
}

class GetSubscriptionPlansUseCase {
  const GetSubscriptionPlansUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<List<Plan>> call() {
    return _repository.getPlans();
  }
}

class CreateCheckoutUseCase {
  const CreateCheckoutUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<String> call(String planCode) {
    return _repository.createCheckout(planCode);
  }
}

class SubscribeUseCase {
  const SubscribeUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<String> call(String planCode) {
    return _repository.subscribe(planCode);
  }
}

class OpenBillingPortalUseCase {
  const OpenBillingPortalUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<BillingPortalSession> call() {
    return _repository.openBillingPortalSession();
  }
}

class OpenBillingPortalUrlUseCase {
  const OpenBillingPortalUrlUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<String> call() {
    return _repository.openPortal();
  }
}

class GetBillingInvoicesUseCase {
  const GetBillingInvoicesUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<List<BillingInvoice>> call() {
    return _repository.getInvoices();
  }
}

class CancelSubscriptionUseCase {
  const CancelSubscriptionUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<Subscription> call() {
    return _repository.cancelSubscription();
  }
}

class ResumeSubscriptionUseCase {
  const ResumeSubscriptionUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<Subscription> call() {
    return _repository.resumeSubscription();
  }
}

class ChangeSubscriptionPlanUseCase {
  const ChangeSubscriptionPlanUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<Subscription> call(String planCode) {
    return _repository.changePlan(planCode);
  }
}

class GetOfflineTrackEntitlementUseCase {
  const GetOfflineTrackEntitlementUseCase(this._repository);

  final SubscriptionRepository _repository;

  Future<OfflineTrackEntitlement> call(String trackId) {
    return _repository.getOfflineTrackEntitlement(trackId);
  }
}
