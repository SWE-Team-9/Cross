import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionRemoteDataSource cancel plan change support', () {
    late String apiConstantsSource;
    late String dataSourceSource;

    setUpAll(() {
      apiConstantsSource = File(
        'lib/core/network/api_constants.dart',
      ).readAsStringSync();

      dataSourceSource = File(
        'lib/features/premium/data/datasources/subscription_remote_data_source.dart',
      ).readAsStringSync();
    });

    test('adds cancel plan change API constant', () {
      expect(
        apiConstantsSource,
        contains('static const String subscriptionCancelPlanChange'),
      );
      expect(
        apiConstantsSource,
        contains(r"'$subscriptionsBase/cancel-plan-change'"),
      );
    });

    test(
        'keeps cancel plan change endpoint near premium subscription endpoints',
        () {
      final changePlanIndex = apiConstantsSource.indexOf(
        'subscriptionChangePlan',
      );
      final cancelPlanChangeIndex = apiConstantsSource.indexOf(
        'subscriptionCancelPlanChange',
      );
      final cancelSubscriptionIndex = apiConstantsSource.indexOf(
        'subscriptionCancel =',
      );

      expect(changePlanIndex, isNonNegative);
      expect(cancelPlanChangeIndex, isNonNegative);
      expect(cancelSubscriptionIndex, isNonNegative);
      expect(changePlanIndex, lessThan(cancelPlanChangeIndex));
      expect(cancelPlanChangeIndex, lessThan(cancelSubscriptionIndex));
    });

    test('adds cancel plan change to remote data source contract', () {
      expect(
        dataSourceSource,
        contains('Future<Subscription> cancelPlanChange();'),
      );

      final changePlanIndex = dataSourceSource.indexOf(
        'Future<Subscription> changePlan({',
      );
      final cancelPlanChangeIndex = dataSourceSource.indexOf(
        'Future<Subscription> cancelPlanChange();',
      );
      final offlineEntitlementIndex = dataSourceSource.indexOf(
        'Future<OfflineTrackEntitlement> getOfflineTrackEntitlement({',
      );

      expect(changePlanIndex, isNonNegative);
      expect(cancelPlanChangeIndex, isNonNegative);
      expect(offlineEntitlementIndex, isNonNegative);
      expect(changePlanIndex, lessThan(cancelPlanChangeIndex));
      expect(cancelPlanChangeIndex, lessThan(offlineEntitlementIndex));
    });

    test('implements cancel plan change through POST request', () {
      expect(
        dataSourceSource,
        contains('Future<Subscription> cancelPlanChange() async'),
      );
      expect(
        dataSourceSource,
        contains('ApiConstants.subscriptionCancelPlanChange'),
      );
      expect(
        dataSourceSource,
        contains('final response = await _dioClient.post('),
      );
    });

    test('parses cancel plan change response into subscription entity', () {
      final methodStart = dataSourceSource.indexOf(
        'Future<Subscription> cancelPlanChange() async',
      );
      final nextOverride = dataSourceSource.indexOf(
        '@override',
        methodStart + 1,
      );

      expect(methodStart, isNonNegative);
      expect(nextOverride, isNonNegative);

      final methodBody = dataSourceSource.substring(methodStart, nextOverride);

      expect(methodBody,
          contains('final payload = _extractPayloadMap(response.data);'));
      expect(methodBody, contains('return Subscription.fromJson(payload);'));
    });

    test('does not add frontend call for backend-only webhook endpoint', () {
      expect(
        apiConstantsSource,
        isNot(contains('/webhook')),
      );
      expect(
        dataSourceSource,
        isNot(contains('/webhook')),
      );
      expect(
        dataSourceSource,
        isNot(contains('subscriptionWebhook')),
      );
    });
  });
}
