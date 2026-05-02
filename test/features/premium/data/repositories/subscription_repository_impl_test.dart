import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/subscription_repository_impl.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late SubscriptionRepositoryImpl repository;

  setUp(() {
    dioClient = MockDioClient();
    repository = SubscriptionRepositoryImpl(dioClient);
  });

  test('getMySubscription parses nested subscription payload', () async {
    when(() => dioClient.get('/api/v1/subscriptions/me')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/subscriptions/me'),
        data: <String, dynamic>{
          'data': <String, dynamic>{
            'planCode': 'PRO',
            'uploadLimit': 100,
            'uploadedTracks': 4,
            'remainingUploads': 96,
            'cancelAtPeriodEnd': true,
            'canDownload': true,
            'adsEnabled': false,
          },
        },
      ),
    );

    final subscription = await repository.getMySubscription();

    expect(subscription.subscriptionType, 'PRO');
    expect(subscription.uploadLimit, 100);
    expect(subscription.uploadedTracks, 4);
    expect(subscription.remainingUploads, 96);
    expect(subscription.cancelAtPeriodEnd, isTrue);
    expect(subscription.canDownload, isTrue);
    expect(subscription.adsEnabled, isFalse);
  });

  test('createCheckout and openPortal return URLs', () async {
    when(() => dioClient.post(
          '/api/v1/subscriptions/checkout',
          data: {
            'planCode': 'PRO',
            'returnUrl': 'app://success',
            'cancelUrl': 'app://cancel',
          },
        )).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/subscriptions/checkout'),
        data: {'checkoutUrl': 'https://checkout.example'},
      ),
    );
    when(() => dioClient.post(
          '/api/v1/subscriptions/portal',
          data: {'returnUrl': 'app://settings'},
        )).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/subscriptions/portal'),
        data: {'portalUrl': 'https://portal.example'},
      ),
    );

    expect(await repository.createCheckout('PRO'), 'https://checkout.example');
    expect(await repository.openPortal(), 'https://portal.example');
  });

  test('getPlans parses top-level plan list', () async {
    when(() => dioClient.get('/api/v1/subscriptions/plans')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/subscriptions/plans'),
        data: [
          <String, dynamic>{
            'code': 'PRO',
            'name': 'Pro',
            'description': 'More uploads',
            'price': 9,
            'interval': 'month',
          },
        ],
      ),
    );

    final plans = await repository.getPlans();

    expect(plans.single.code, 'PRO');
    expect(plans.single.price, 9);
  });

  test('subscription actions hit expected endpoints', () async {
    when(() => dioClient.post('/api/v1/subscriptions/cancel')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/subscriptions/cancel'),
      ),
    );
    when(() => dioClient.post('/api/v1/subscriptions/resume')).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/subscriptions/resume'),
      ),
    );
    when(() => dioClient.post(
          '/api/v1/subscriptions/change-plan',
          data: {'planCode': 'PRO'},
        )).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions:
            RequestOptions(path: '/api/v1/subscriptions/change-plan'),
      ),
    );

    await repository.cancelSubscription();
    await repository.resumeSubscription();
    await repository.changePlan('PRO');

    verify(() => dioClient.post('/api/v1/subscriptions/cancel')).called(1);
    verify(() => dioClient.post('/api/v1/subscriptions/resume')).called(1);
    verify(() => dioClient.post(
          '/api/v1/subscriptions/change-plan',
          data: {'planCode': 'PRO'},
        )).called(1);
  });
}
