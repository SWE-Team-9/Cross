import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionCubit cancel plan change support', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/premium/presentation/bloc/subscription_cubit.dart',
      ).readAsStringSync();
    });

    test('defines cancel plan change action', () {
      expect(
        source,
        contains('Future<void> cancelPlanChange() async'),
      );
    });

    test('sets action loading before canceling scheduled plan change', () {
      final methodBody = _methodBody(
        source,
        'Future<void> cancelPlanChange() async',
        'Future<String> openBillingPortal() async',
      );

      expect(
        methodBody,
        contains('actionStatus: SubscriptionActionStatus.loading'),
      );
      expect(
        methodBody,
        contains('clearActionMessage: true'),
      );
      expect(
        methodBody,
        contains('clearActionErrorMessage: true'),
      );
    });

    test('calls repository cancel plan change', () {
      final methodBody = _methodBody(
        source,
        'Future<void> cancelPlanChange() async',
        'Future<String> openBillingPortal() async',
      );

      expect(
        methodBody,
        contains('final subscription = await repository.cancelPlanChange();'),
      );
    });

    test('emits success state and message after canceling scheduled plan change',
        () {
      final methodBody = _methodBody(
        source,
        'Future<void> cancelPlanChange() async',
        'Future<String> openBillingPortal() async',
      );

      expect(
        methodBody,
        contains('status: SubscriptionStatus.loaded'),
      );
      expect(
        methodBody,
        contains('actionStatus: SubscriptionActionStatus.success'),
      );
      expect(
        methodBody,
        contains('subscription: subscription'),
      );
      expect(
        methodBody,
        contains("actionMessage: 'Scheduled plan change canceled.'"),
      );
      expect(
        methodBody,
        contains('clearActionErrorMessage: true'),
      );
    });

    test('refreshes billing after canceling scheduled plan change', () {
      final methodBody = _methodBody(
        source,
        'Future<void> cancelPlanChange() async',
        'Future<String> openBillingPortal() async',
      );

      expect(
        methodBody,
        contains('await _refreshBillingAfterAction();'),
      );
    });

    test('emits readable error message when cancel plan change fails', () {
      final methodBody = _methodBody(
        source,
        'Future<void> cancelPlanChange() async',
        'Future<String> openBillingPortal() async',
      );

      expect(
        methodBody,
        contains('catch (error)'),
      );
      expect(
        methodBody,
        contains('actionStatus: SubscriptionActionStatus.failure'),
      );
      expect(
        methodBody,
        contains('actionErrorMessage: _readableError(error)'),
      );
      expect(
        methodBody,
        contains('clearActionMessage: true'),
      );
    });

    test('keeps existing subscription actions intact', () {
      expect(
        source,
        contains('Future<void> cancel() async'),
      );
      expect(
        source,
        contains('Future<void> resume() async'),
      );
      expect(
        source,
        contains('Future<void> changePlan(String plan) async'),
      );
      expect(
        source,
        contains('Future<String> openBillingPortal() async'),
      );
    });

    test('keeps billing refresh helper after action success', () {
      expect(
        source,
        contains('Future<void> _refreshBillingAfterAction() async'),
      );
      expect(
        source,
        contains('repository.getMySubscription()'),
      );
      expect(
        source,
        contains('repository.getPlans()'),
      );
      expect(
        source,
        contains('repository.getInvoices()'),
      );
    });
  });
}

String _methodBody(
  String source,
  String startMarker,
  String endMarker,
) {
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker, start + startMarker.length);

  expect(start, isNonNegative);
  expect(end, isNonNegative);

  return source.substring(start, end);
}