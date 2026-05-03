import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/premium/data/datasources/subscription_remote_data_source.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient dioClient;
  late SubscriptionRemoteDataSourceImpl dataSource;

  setUp(() {
    dioClient = MockDioClient();
    dataSource = SubscriptionRemoteDataSourceImpl(dioClient);
  });

  Response<dynamic> response(dynamic data) {
    return Response<dynamic>(
      data: data,
      requestOptions: RequestOptions(path: '/test'),
      statusCode: 200,
    );
  }

  Map<String, dynamic> subscriptionJson({
    String planCode = 'PRO',
    bool isPremium = true,
  }) {
    return <String, dynamic>{
      'userId': 'user-uuid-1',
      'planCode': planCode,
      'subscriptionType': planCode,
      'subscriptionStatus': 'ACTIVE',
      'planName': planCode == 'GO_PLUS' ? 'GO+' : 'Pro',
      'isPremium': isPremium,
      'adsEnabled': !isPremium,
      'canDownload': isPremium,
      'supportLevel': isPremium ? 'priority' : 'community',
      'uploadLimit': isPremium ? 100 : 3,
      'uploadLimitDisplay': isPremium ? '100' : '3',
      'uploadedTracks': 5,
      'remainingUploads': isPremium ? 95 : 0,
      'currentPeriodEnd': '2026-05-01T00:00:00.000Z',
      'renewalDate': '2026-05-01T00:00:00.000Z',
      'cancelAtPeriodEnd': false,
      'canResume': false,
    };
  }

  Map<String, dynamic> planJson({
    String code = 'PRO',
    String name = 'Pro',
  }) {
    return <String, dynamic>{
      'id': 'plan-$code',
      'code': code,
      'name': name,
      'tier': code,
      'priceCents': code == 'FREE' ? 0 : 999,
      'priceDisplay': code == 'FREE' ? 'Free' : r'$9.99/mo',
      'billingInterval': code == 'FREE' ? null : 'MONTHLY',
      'uploadLimit': code == 'FREE' ? 3 : 100,
      'uploadLimitDisplay': code == 'FREE' ? '3' : '100',
      'isUnlimited': false,
      'trialDays': code == 'FREE' ? 0 : 7,
      'adsEnabled': code == 'FREE',
      'canDownload': code != 'FREE',
      'supportLevel': code == 'FREE' ? 'community' : 'priority',
      'highlightedFeatures': <String>[
        code == 'FREE' ? '3 uploads' : '100 uploads',
      ],
    };
  }

  Map<String, dynamic> invoiceJson() {
    return <String, dynamic>{
      'id': 'billing-invoice-uuid',
      'invoiceId': 'in_mock_abc123',
      'amountDueCents': 999,
      'amountPaidCents': 999,
      'currency': 'USD',
      'status': 'PAID',
      'planName': 'Pro',
      'planTier': 'PRO',
      'dueAt': '2026-04-01T00:00:00.000Z',
      'paidAt': '2026-04-01T00:00:00.000Z',
      'createdAt': '2026-04-01T00:00:00.000Z',
    };
  }

  Map<String, dynamic> portalJson() {
    return <String, dynamic>{
      'url': 'https://billing.stripe.com/session/test',
      'sessionId': 'bps_123',
      'customerId': 'cus_123',
      'returnUrl': 'iqa3://billing/return',
      'expiresAt': '2026-05-01T00:00:00.000Z',
      'paymentMethodSummary': 'Visa •••• 4242',
      'paymentMethod': <String, dynamic>{
        'brand': 'visa',
        'last4': '4242',
      },
      'canUpdatePaymentMethod': true,
      'canCancel': true,
      'canResume': false,
      'canChangePlan': true,
    };
  }

  Map<String, dynamic> offlineEntitlementJson() {
    return <String, dynamic>{
      'trackId': 'track-1',
      'title': 'Midnight Drive',
      'artist': 'DJ Nova',
      'handle': 'djnova',
      'durationMs': 214000,
      'coverArtUrl': 'https://example.com/cover.jpg',
      'downloadUrl': 'https://example.com/audio.mp3',
      'expiresAt': '2026-04-28T14:00:00.000Z',
      'expiresInSeconds': 900,
      'offlineTokenId': 'offline_mock_abc123',
      'planCode': 'PRO',
    };
  }

  group('getMySubscription', () {
    test('calls current subscription endpoint and parses direct payload',
        () async {
      when(
        () => dioClient.get(ApiConstants.mySubscription),
      ).thenAnswer((_) async => response(subscriptionJson()));

      final result = await dataSource.getMySubscription();

      expect(result.userId, 'user-uuid-1');
      expect(result.planCode, 'PRO');
      expect(result.isPremium, isTrue);

      verify(
        () => dioClient.get(ApiConstants.mySubscription),
      ).called(1);
    });

    test('parses subscription from data wrapper and string JSON response',
        () async {
      when(
        () => dioClient.get(ApiConstants.mySubscription),
      ).thenAnswer(
        (_) async => response(
          jsonEncode(
            <String, dynamic>{
              'data': subscriptionJson(planCode: 'GO_PLUS'),
            },
          ),
        ),
      );

      final result = await dataSource.getMySubscription();

      expect(result.planCode, 'GO_PLUS');
      expect(result.isGoPlus, isTrue);
    });

    test('parses subscription from subscription wrapper', () async {
      when(
        () => dioClient.get(ApiConstants.mySubscription),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'subscription': subscriptionJson(),
          },
        ),
      );

      final result = await dataSource.getMySubscription();

      expect(result.planCode, 'PRO');
    });
  });

  group('getPlans', () {
    test('calls plans endpoint and parses direct list response', () async {
      when(
        () => dioClient.get(ApiConstants.subscriptionPlans),
      ).thenAnswer(
        (_) async => response(
          <Map<String, dynamic>>[
            planJson(code: 'FREE', name: 'Free'),
            planJson(),
          ],
        ),
      );

      final result = await dataSource.getPlans();

      expect(result, hasLength(2));
      expect(result.first.code, 'FREE');
      expect(result.last.code, 'PRO');

      verify(
        () => dioClient.get(ApiConstants.subscriptionPlans),
      ).called(1);
    });

    test('parses plans from plans wrapper and string JSON response', () async {
      when(
        () => dioClient.get(ApiConstants.subscriptionPlans),
      ).thenAnswer(
        (_) async => response(
          jsonEncode(
            <String, dynamic>{
              'plans': <Map<String, dynamic>>[
                planJson(code: 'FREE', name: 'Free'),
                planJson(),
              ],
            },
          ),
        ),
      );

      final result = await dataSource.getPlans();

      expect(result.map((plan) => plan.code), <String>['FREE', 'PRO']);
    });

    test('parses plans from data wrapper', () async {
      when(
        () => dioClient.get(ApiConstants.subscriptionPlans),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'data': <Map<String, dynamic>>[
              planJson(),
            ],
          },
        ),
      );

      final result = await dataSource.getPlans();

      expect(result.single.code, 'PRO');
    });
  });

  group('createCheckout', () {
    test('posts planCode and returns checkoutUrl', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionCheckout,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'checkoutUrl': 'https://checkout.example.com/pro',
          },
        ),
      );

      final result = await dataSource.createCheckout(planCode: 'PRO');

      expect(result, 'https://checkout.example.com/pro');

      verify(
        () => dioClient.post(
          ApiConstants.subscriptionCheckout,
          data: <String, dynamic>{
            'planCode': 'PRO',
          },
        ),
      ).called(1);
    });

    test('posts optional returnUrl and cancelUrl when non-empty', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionCheckout,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'url': 'https://checkout.example.com/pro',
          },
        ),
      );

      await dataSource.createCheckout(
        planCode: 'PRO',
        returnUrl: '  iqa3://checkout/success  ',
        cancelUrl: '  iqa3://checkout/cancel  ',
      );

      verify(
        () => dioClient.post(
          ApiConstants.subscriptionCheckout,
          data: <String, dynamic>{
            'planCode': 'PRO',
            'returnUrl': 'iqa3://checkout/success',
            'cancelUrl': 'iqa3://checkout/cancel',
          },
        ),
      ).called(1);
    });

    test('can return redirectUrl from data wrapper', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionCheckout,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'data': <String, dynamic>{
              'redirectUrl': 'https://checkout.example.com/redirect',
            },
          },
        ),
      );

      final result = await dataSource.createCheckout(planCode: 'PRO');

      expect(result, 'https://checkout.example.com/redirect');
    });
  });

  group('subscribe', () {
    test('posts subscriptionType and returns url', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionSubscribe,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'url': 'https://subscribe.example.com/pro',
          },
        ),
      );

      final result = await dataSource.subscribe(subscriptionType: 'PRO');

      expect(result, 'https://subscribe.example.com/pro');

      verify(
        () => dioClient.post(
          ApiConstants.subscriptionSubscribe,
          data: <String, dynamic>{
            'subscriptionType': 'PRO',
          },
        ),
      ).called(1);
    });

    test('posts optional paymentMethodId when non-empty', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionSubscribe,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'message': 'Subscription created',
          },
        ),
      );

      final result = await dataSource.subscribe(
        subscriptionType: 'PRO',
        paymentMethodId: '  pm_123  ',
      );

      expect(result, 'Subscription created');

      verify(
        () => dioClient.post(
          ApiConstants.subscriptionSubscribe,
          data: <String, dynamic>{
            'subscriptionType': 'PRO',
            'paymentMethodId': 'pm_123',
          },
        ),
      ).called(1);
    });
  });

  group('openBillingPortalSession', () {
    test('posts portal request and parses direct portal payload', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionPortal,
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response(portalJson()));

      final result = await dataSource.openBillingPortalSession(
        returnUrl: '  iqa3://billing/return  ',
      );

      expect(result.sessionId, 'bps_123');
      expect(result.launchUrl, 'https://billing.stripe.com/session/test');
      expect(result.canUpdatePaymentMethod, isTrue);
      expect(result.canCancel, isTrue);
      expect(result.canChangePlan, isTrue);

      verify(
        () => dioClient.post(
          ApiConstants.subscriptionPortal,
          data: <String, dynamic>{
            'returnUrl': 'iqa3://billing/return',
            'flow': 'billing',
          },
        ),
      ).called(1);
    });

    test('normalizes portalSessionId and payment method map summary', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionPortal,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'portalSessionId': 'bps_456',
            'portalUrl': 'https://billing.example.com/session/test',
            'paymentMethodSummary': <String, dynamic>{
              'brand': 'visa',
              'last4': '4242',
            },
          },
        ),
      );

      final result = await dataSource.openBillingPortalSession();

      expect(result.sessionId, 'bps_456');
      expect(result.url, 'https://billing.example.com/session/test');
      expect(result.paymentMethodSummary, 'Visa •••• 4242');
      expect(
        result.paymentMethod,
        <String, dynamic>{
          'brand': 'visa',
          'last4': '4242',
        },
      );
    });

    test('normalizes capabilities object', () async {
      when(
        () => dioClient.post(
          ApiConstants.subscriptionPortal,
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'url': 'https://billing.example.com/session/test',
            'capabilities': <String, dynamic>{
              'can_update_payment_method': true,
              'can_cancel': true,
              'can_resume': false,
              'can_change_plan': true,
            },
          },
        ),
      );

      final result = await dataSource.openBillingPortalSession();

      expect(result.canUpdatePaymentMethod, isTrue);
      expect(result.canCancel, isTrue);
      expect(result.canResume, isFalse);
      expect(result.canChangePlan, isTrue);
    });
  });

  group('getInvoices', () {
    test('calls invoices endpoint and parses direct list response', () async {
      when(
        () => dioClient.get(ApiConstants.subscriptionInvoices),
      ).thenAnswer(
        (_) async => response(
          <Map<String, dynamic>>[
            invoiceJson(),
          ],
        ),
      );

      final result = await dataSource.getInvoices();

      expect(result, hasLength(1));
      expect(result.single.invoiceId, 'in_mock_abc123');

      verify(
        () => dioClient.get(ApiConstants.subscriptionInvoices),
      ).called(1);
    });

    test('parses invoices from invoices wrapper and string JSON response',
        () async {
      when(
        () => dioClient.get(ApiConstants.subscriptionInvoices),
      ).thenAnswer(
        (_) async => response(
          jsonEncode(
            <String, dynamic>{
              'invoices': <Map<String, dynamic>>[
                invoiceJson(),
              ],
            },
          ),
        ),
      );

      final result = await dataSource.getInvoices();

      expect(result.single.status, 'PAID');
    });

    test('parses invoices from items wrapper', () async {
      when(
        () => dioClient.get(ApiConstants.subscriptionInvoices),
      ).thenAnswer(
        (_) async => response(
          <String, dynamic>{
            'items': <Map<String, dynamic>>[
              invoiceJson(),
            ],
          },
        ),
      );

      final result = await dataSource.getInvoices();

      expect(result.single.amountPaidCents, 999);
    });
  });

  test('cancelSubscription posts cancel endpoint', () async {
    when(
      () => dioClient.post(ApiConstants.subscriptionCancel),
    ).thenAnswer((_) async => response(<String, dynamic>{'message': 'ok'}));

    await dataSource.cancelSubscription();

    verify(
      () => dioClient.post(ApiConstants.subscriptionCancel),
    ).called(1);
  });

  test('resumeSubscription posts resume endpoint and parses subscription',
      () async {
    when(
      () => dioClient.post(ApiConstants.subscriptionResume),
    ).thenAnswer((_) async => response(subscriptionJson()));

    final result = await dataSource.resumeSubscription();

    expect(result.planCode, 'PRO');

    verify(
      () => dioClient.post(ApiConstants.subscriptionResume),
    ).called(1);
  });

  test('changePlan posts planCode and parses subscription', () async {
    when(
      () => dioClient.post(
        ApiConstants.subscriptionChangePlan,
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => response(subscriptionJson(planCode: 'GO_PLUS')),
    );

    final result = await dataSource.changePlan(planCode: 'GO_PLUS');

    expect(result.planCode, 'GO_PLUS');

    verify(
      () => dioClient.post(
        ApiConstants.subscriptionChangePlan,
        data: <String, dynamic>{
          'planCode': 'GO_PLUS',
        },
      ),
    ).called(1);
  });

  test('getOfflineTrackEntitlement calls offline entitlement endpoint',
      () async {
    when(
      () => dioClient.get(
        ApiConstants.subscriptionOfflineTrackPath('track-1'),
      ),
    ).thenAnswer((_) async => response(offlineEntitlementJson()));

    final result = await dataSource.getOfflineTrackEntitlement(
      trackId: 'track-1',
    );

    expect(result.trackId, 'track-1');
    expect(result.title, 'Midnight Drive');
    expect(result.planCode, 'PRO');

    verify(
      () => dioClient.get(
        ApiConstants.subscriptionOfflineTrackPath('track-1'),
      ),
    ).called(1);
  });

  test('throws FormatException when list endpoint returns object without list',
      () async {
    when(
      () => dioClient.get(ApiConstants.subscriptionPlans),
    ).thenAnswer(
      (_) async => response(
        <String, dynamic>{
          'message': 'not a list',
        },
      ),
    );

    expect(
      () => dataSource.getPlans(),
      throwsA(isA<FormatException>()),
    );
  });

  test('throws FormatException when object endpoint returns list', () async {
    when(
      () => dioClient.get(ApiConstants.mySubscription),
    ).thenAnswer((_) async => response(<dynamic>[]));

    expect(
      () => dataSource.getMySubscription(),
      throwsA(isA<FormatException>()),
    );
  });

  test('propagates dioClient exceptions', () async {
    final exception = DioException(
      requestOptions: RequestOptions(path: ApiConstants.mySubscription),
    );

    when(
      () => dioClient.get(ApiConstants.mySubscription),
    ).thenThrow(exception);

    expect(
      () => dataSource.getMySubscription(),
      throwsA(same(exception)),
    );
  });
}
