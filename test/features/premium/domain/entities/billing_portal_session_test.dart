import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';

void main() {
  group('BillingPortalSession', () {
    test('uses safe defaults', () {
      const session = BillingPortalSession();

      expect(session.url, '');
      expect(session.portalUrl, '');
      expect(session.sessionId, '');
      expect(session.customerId, '');
      expect(session.returnUrl, '');
      expect(session.expiresAt, isNull);
      expect(session.paymentMethodSummary, '');
      expect(session.paymentMethod, isNull);
      expect(session.canUpdatePaymentMethod, isFalse);
      expect(session.canCancel, isFalse);
      expect(session.canResume, isFalse);
      expect(session.canChangePlan, isFalse);

      expect(session.launchUrl, '');
      expect(session.hasLaunchUrl, isFalse);
      expect(session.hasPaymentMethod, isFalse);
      expect(session.isExpired, isFalse);
    });

    test('fromJson parses direct portal response shape', () {
      final session = BillingPortalSession.fromJson(
        const <String, dynamic>{
          'url': 'https://billing.stripe.com/session/test',
          'portalUrl': 'https://billing.example.com/session/test',
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
        },
      );

      expect(session.url, 'https://billing.stripe.com/session/test');
      expect(session.portalUrl, 'https://billing.example.com/session/test');
      expect(session.sessionId, 'bps_123');
      expect(session.customerId, 'cus_123');
      expect(session.returnUrl, 'iqa3://billing/return');
      expect(session.expiresAt, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(session.paymentMethodSummary, 'Visa •••• 4242');
      expect(
        session.paymentMethod,
        <String, dynamic>{
          'brand': 'visa',
          'last4': '4242',
        },
      );
      expect(session.canUpdatePaymentMethod, isTrue);
      expect(session.canCancel, isTrue);
      expect(session.canResume, isFalse);
      expect(session.canChangePlan, isTrue);

      expect(session.launchUrl, 'https://billing.stripe.com/session/test');
      expect(session.hasLaunchUrl, isTrue);
      expect(session.hasPaymentMethod, isTrue);
    });

    test('fromJson accepts snake case keys', () {
      final session = BillingPortalSession.fromJson(
        const <String, dynamic>{
          'portal_url': 'https://billing.example.com/session/test',
          'session_id': 'bps_123',
          'customer_id': 'cus_123',
          'return_url': 'iqa3://billing/return',
          'expires_at': '2026-05-01T00:00:00.000Z',
          'payment_method_summary': 'Mastercard •••• 1111',
          'payment_method': <String, dynamic>{
            'brand': 'mastercard',
            'last4': '1111',
          },
          'can_update_payment_method': true,
          'can_cancel': true,
          'can_resume': true,
          'can_change_plan': true,
        },
      );

      expect(session.url, '');
      expect(session.portalUrl, 'https://billing.example.com/session/test');
      expect(session.sessionId, 'bps_123');
      expect(session.customerId, 'cus_123');
      expect(session.returnUrl, 'iqa3://billing/return');
      expect(session.expiresAt, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(session.paymentMethodSummary, 'Mastercard •••• 1111');
      expect(
        session.paymentMethod,
        <String, dynamic>{
          'brand': 'mastercard',
          'last4': '1111',
        },
      );
      expect(session.canUpdatePaymentMethod, isTrue);
      expect(session.canCancel, isTrue);
      expect(session.canResume, isTrue);
      expect(session.canChangePlan, isTrue);

      expect(session.launchUrl, 'https://billing.example.com/session/test');
      expect(session.hasLaunchUrl, isTrue);
      expect(session.hasPaymentMethod, isTrue);
    });

    test('fromJson accepts id as sessionId fallback', () {
      final session = BillingPortalSession.fromJson(
        const <String, dynamic>{
          'id': 'bps_456',
        },
      );

      expect(session.sessionId, 'bps_456');
    });

    test('fromJson reads capabilities object', () {
      final session = BillingPortalSession.fromJson(
        const <String, dynamic>{
          'capabilities': <String, dynamic>{
            'canUpdatePaymentMethod': true,
            'canCancel': true,
            'canResume': false,
            'canChangePlan': true,
          },
        },
      );

      expect(session.canUpdatePaymentMethod, isTrue);
      expect(session.canCancel, isTrue);
      expect(session.canResume, isFalse);
      expect(session.canChangePlan, isTrue);
    });

    test('fromJson reads snake case permissions object', () {
      final session = BillingPortalSession.fromJson(
        const <String, dynamic>{
          'permissions': <String, dynamic>{
            'can_update_payment_method': true,
            'can_cancel': false,
            'can_resume': true,
            'can_change_plan': true,
          },
        },
      );

      expect(session.canUpdatePaymentMethod, isTrue);
      expect(session.canCancel, isFalse);
      expect(session.canResume, isTrue);
      expect(session.canChangePlan, isTrue);
    });

    test('direct capability fields override capabilities object', () {
      final session = BillingPortalSession.fromJson(
        const <String, dynamic>{
          'canCancel': true,
          'capabilities': <String, dynamic>{
            'canCancel': false,
          },
        },
      );

      expect(session.canCancel, isTrue);
    });

    test('launchUrl prefers url over portalUrl', () {
      const session = BillingPortalSession(
        url: 'https://stripe.example.com',
        portalUrl: 'https://portal.example.com',
      );

      expect(session.launchUrl, 'https://stripe.example.com');
    });

    test('launchUrl falls back to portalUrl', () {
      const session = BillingPortalSession(
        portalUrl: 'https://portal.example.com',
      );

      expect(session.launchUrl, 'https://portal.example.com');
      expect(session.hasLaunchUrl, isTrue);
    });

    test('hasPaymentMethod can be true from payment method map only', () {
      const session = BillingPortalSession(
        paymentMethod: <String, dynamic>{
          'brand': 'visa',
        },
      );

      expect(session.hasPaymentMethod, isTrue);
    });

    test('isExpired returns true for a past expiry date', () {
      final session = BillingPortalSession(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
      );

      expect(session.isExpired, isTrue);
    });

    test('isExpired returns false for a future expiry date', () {
      final session = BillingPortalSession(
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      );

      expect(session.isExpired, isFalse);
    });

    test('toJson serializes all fields', () {
      final session = BillingPortalSession(
        url: 'https://billing.stripe.com/session/test',
        portalUrl: 'https://billing.example.com/session/test',
        sessionId: 'bps_123',
        customerId: 'cus_123',
        returnUrl: 'iqa3://billing/return',
        expiresAt: DateTime.parse('2026-05-01T00:00:00.000Z'),
        paymentMethodSummary: 'Visa •••• 4242',
        paymentMethod: const <String, dynamic>{
          'brand': 'visa',
          'last4': '4242',
        },
        canUpdatePaymentMethod: true,
        canCancel: true,
        canResume: false,
        canChangePlan: true,
      );

      expect(
        session.toJson(),
        <String, dynamic>{
          'url': 'https://billing.stripe.com/session/test',
          'portalUrl': 'https://billing.example.com/session/test',
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
        },
      );
    });

    test('copyWith updates selected fields only', () {
      const session = BillingPortalSession(
        sessionId: 'bps_123',
        url: 'https://old.example.com',
        canCancel: false,
      );

      final updated = session.copyWith(
        url: 'https://new.example.com',
        canCancel: true,
      );

      expect(updated.sessionId, 'bps_123');
      expect(updated.url, 'https://new.example.com');
      expect(updated.canCancel, isTrue);
    });

    test('copyWith clears nullable fields', () {
      final session = BillingPortalSession(
        expiresAt: DateTime.parse('2026-05-01T00:00:00.000Z'),
        paymentMethod: const <String, dynamic>{
          'brand': 'visa',
        },
      );

      final updated = session.copyWith(
        clearExpiresAt: true,
        clearPaymentMethod: true,
      );

      expect(updated.expiresAt, isNull);
      expect(updated.paymentMethod, isNull);
    });

    test('compares value equality including nested payment method map', () {
      const first = BillingPortalSession(
        sessionId: 'bps_123',
        paymentMethod: <String, dynamic>{
          'card': <String, dynamic>{
            'brand': 'visa',
            'last4': '4242',
          },
        },
      );

      const second = BillingPortalSession(
        sessionId: 'bps_123',
        paymentMethod: <String, dynamic>{
          'card': <String, dynamic>{
            'brand': 'visa',
            'last4': '4242',
          },
        },
      );

      const third = BillingPortalSession(
        sessionId: 'bps_123',
        paymentMethod: <String, dynamic>{
          'card': <String, dynamic>{
            'brand': 'visa',
            'last4': '1111',
          },
        },
      );

      expect(first, second);
      expect(first == third, isFalse);
      expect(first.hashCode, second.hashCode);
    });
  });
}
