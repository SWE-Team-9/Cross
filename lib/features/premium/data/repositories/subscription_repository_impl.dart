import '../../../../core/network/dio_client.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/plan.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final DioClient _dioClient;

  SubscriptionRepositoryImpl(this._dioClient);

  @override
  Future<Subscription> getMySubscription() async {
    final response = await _dioClient.get('/api/v1/subscriptions/me');

    final data = response.data is Map && response.data.containsKey('data')
        ? response.data['data']
        : response.data;

    return Subscription(
      subscriptionType: data['planCode'] ?? 'FREE',
      uploadLimit: data['uploadLimit'] ?? 3,
      uploadedTracks: data['uploadedTracks'] ?? 0,
      remainingUploads: data['remainingUploads'] ?? 0,
      cancelAtPeriodEnd: data['cancelAtPeriodEnd'] ?? false,
    );
  }

  @override
  Future<String> createCheckout(String plan) async {
    final response = await _dioClient.post(
      '/api/v1/subscriptions/checkout',
      data: {
        "planCode": plan,
        "returnUrl": "app://success",
        "cancelUrl": "app://cancel",
      },
    );

    return response.data['checkoutUrl'];
  }

  @override
  Future<List<Plan>> getPlans() async {
    final response = await _dioClient.get('/api/v1/subscriptions/plans');

    final data = response.data is Map && response.data.containsKey('data')
        ? response.data['data']
        : response.data;

    final list = data as List;

    return list.map((e) => Plan.fromJson(e)).toList();
  }

  @override
  Future<void> cancelSubscription() async {
    await _dioClient.post('/api/v1/subscriptions/cancel');
  }

  @override
  Future<void> resumeSubscription() async {
    await _dioClient.post('/api/v1/subscriptions/resume');
  }

  @override
  Future<void> changePlan(String plan) async {
    await _dioClient.post(
      '/api/v1/subscriptions/change-plan',
      data: {"planCode": plan},
    );
  }

  @override
  Future<String> openPortal() async {
    final response = await _dioClient.post(
      '/api/v1/subscriptions/portal',
      data: {
        "returnUrl": "app://settings",
      },
    );

    return response.data['portalUrl'];
  }
}
