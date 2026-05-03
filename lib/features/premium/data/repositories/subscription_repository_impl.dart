import '../../../../core/network/dio_client.dart';
import '../../domain/entities/billing_invoice.dart';
import '../../domain/entities/billing_portal_session.dart';
import '../../domain/entities/offline_track_entitlement.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl([dynamic dependency])
      : _remoteDataSource = _resolveRemoteDataSource(dependency);

  final SubscriptionRemoteDataSource _remoteDataSource;

  @override
  Future<Subscription> getMySubscription() {
    return _remoteDataSource.getMySubscription();
  }

  @override
  Future<List<Plan>> getPlans() {
    return _remoteDataSource.getPlans();
  }

  @override
  Future<String> createCheckout(String plan) {
    return _remoteDataSource.createCheckout(
      planCode: plan,
    );
  }

  @override
  Future<String> subscribe(String plan) {
    return _remoteDataSource.subscribe(
      subscriptionType: plan,
    );
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() {
    return _remoteDataSource.openBillingPortalSession();
  }

  @override
  Future<String> openPortal() async {
    final session = await openBillingPortalSession();
    return session.launchUrl;
  }

  @override
  Future<List<BillingInvoice>> getInvoices() {
    return _remoteDataSource.getInvoices();
  }

  @override
  Future<Subscription> cancelSubscription() async {
    await _remoteDataSource.cancelSubscription();
    return _remoteDataSource.getMySubscription();
  }

  @override
  Future<Subscription> resumeSubscription() {
    return _remoteDataSource.resumeSubscription();
  }

  @override
  Future<Subscription> changePlan(String plan) {
    return _remoteDataSource.changePlan(
      planCode: plan,
    );
  }

  @override
  Future<Subscription> cancelPlanChange() {
    return _remoteDataSource.cancelPlanChange();
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(String trackId) {
    return _remoteDataSource.getOfflineTrackEntitlement(
      trackId: trackId,
    );
  }
}

SubscriptionRemoteDataSource _resolveRemoteDataSource(dynamic dependency) {
  if (dependency is SubscriptionRemoteDataSource) {
    return dependency;
  }

  if (dependency is DioClient) {
    return SubscriptionRemoteDataSourceImpl(dependency);
  }

  throw ArgumentError(
    'SubscriptionRepositoryImpl requires a SubscriptionRemoteDataSource '
    'or DioClient dependency.',
  );
}
