import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionRepository cancel plan change support', () {
    late String contractSource;
    late String implSource;
    late String mockSource;

    setUpAll(() {
      contractSource = File(
        'lib/features/premium/domain/repositories/subscription_repository.dart',
      ).readAsStringSync();

      implSource = File(
        'lib/features/premium/data/repositories/subscription_repository_impl.dart',
      ).readAsStringSync();

      mockSource = File(
        'lib/features/premium/data/repositories/mock_subscription_repository.dart',
      ).readAsStringSync();
    });

    test('adds cancel plan change to repository contract', () {
      expect(
        contractSource,
        contains('Future<Subscription> cancelPlanChange();'),
      );

      final changePlanIndex = contractSource.indexOf(
        'Future<Subscription> changePlan(String plan);',
      );
      final cancelPlanChangeIndex = contractSource.indexOf(
        'Future<Subscription> cancelPlanChange();',
      );
      final offlineEntitlementIndex = contractSource.indexOf(
        'Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(String trackId);',
      );

      expect(changePlanIndex, isNonNegative);
      expect(cancelPlanChangeIndex, isNonNegative);
      expect(offlineEntitlementIndex, isNonNegative);
      expect(changePlanIndex, lessThan(cancelPlanChangeIndex));
      expect(cancelPlanChangeIndex, lessThan(offlineEntitlementIndex));
    });

    test('repository implementation forwards cancel plan change to remote data source', () {
      expect(
        implSource,
        contains('Future<Subscription> cancelPlanChange()'),
      );
      expect(
        implSource,
        contains('return _remoteDataSource.cancelPlanChange();'),
      );

      final changePlanIndex = implSource.indexOf(
        'Future<Subscription> changePlan(String plan)',
      );
      final cancelPlanChangeIndex = implSource.indexOf(
        'Future<Subscription> cancelPlanChange()',
      );
      final offlineEntitlementIndex = implSource.indexOf(
        'Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(String trackId)',
      );

      expect(changePlanIndex, isNonNegative);
      expect(cancelPlanChangeIndex, isNonNegative);
      expect(offlineEntitlementIndex, isNonNegative);
      expect(changePlanIndex, lessThan(cancelPlanChangeIndex));
      expect(cancelPlanChangeIndex, lessThan(offlineEntitlementIndex));
    });

    test('repository implementation keeps formatted invoices method', () {
      expect(
        implSource,
        contains('Future<List<BillingInvoice>> getInvoices() {\n    return _remoteDataSource.getInvoices();\n  }'),
      );
    });

    test('mock repository implements cancel plan change', () {
      expect(
        mockSource,
        contains('Future<Subscription> cancelPlanChange() async'),
      );
      expect(
        mockSource,
        contains('if (!_current.hasPendingDowngrade)'),
      );
      expect(
        mockSource,
        contains('return _current;'),
      );
      expect(
        mockSource,
        contains('_current = _current.copyWith(clearPendingDowngrade: true);'),
      );
    });

    test('mock cancel plan change is placed after change plan behavior', () {
      final changePlanIndex = mockSource.indexOf(
        'Future<Subscription> changePlan(String plan) async',
      );
      final cancelPlanChangeIndex = mockSource.indexOf(
        'Future<Subscription> cancelPlanChange() async',
      );
      final offlineEntitlementIndex = mockSource.indexOf(
        'Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(',
      );

      expect(changePlanIndex, isNonNegative);
      expect(cancelPlanChangeIndex, isNonNegative);
      expect(offlineEntitlementIndex, isNonNegative);
      expect(changePlanIndex, lessThan(cancelPlanChangeIndex));
      expect(cancelPlanChangeIndex, lessThan(offlineEntitlementIndex));
    });

    test('keeps legacy open portal compatibility', () {
      expect(
        contractSource,
        contains('Future<String> openPortal() async'),
      );
      expect(
        implSource,
        contains('Future<String> openPortal() async'),
      );
      expect(
        mockSource,
        contains('Future<String> openPortal() async'),
      );
    });
  });
}