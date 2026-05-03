import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';

void main() {
  group('BillingInvoice', () {
    test('uses safe defaults', () {
      const invoice = BillingInvoice();

      expect(invoice.id, '');
      expect(invoice.invoiceId, '');
      expect(invoice.amountDueCents, 0);
      expect(invoice.amountPaidCents, 0);
      expect(invoice.currency, 'USD');
      expect(invoice.status, '');
      expect(invoice.planName, '');
      expect(invoice.planTier, '');
      expect(invoice.dueAt, isNull);
      expect(invoice.paidAt, isNull);
      expect(invoice.createdAt, isNull);

      expect(invoice.normalizedStatus, '');
      expect(invoice.normalizedCurrency, 'USD');
      expect(invoice.isPaid, isFalse);
      expect(invoice.isOpen, isFalse);
      expect(invoice.isFailed, isFalse);
      expect(invoice.displayStatus, 'Unknown');
      expect(invoice.displayAmountDue, r'$0');
      expect(invoice.displayAmountPaid, r'$0');
      expect(invoice.displayPlanName, '');
    });

    test('fromJson parses swagger invoice response shape', () {
      final invoice = BillingInvoice.fromJson(
        const <String, dynamic>{
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
        },
      );

      expect(invoice.id, 'billing-invoice-uuid');
      expect(invoice.invoiceId, 'in_mock_abc123');
      expect(invoice.amountDueCents, 999);
      expect(invoice.amountPaidCents, 999);
      expect(invoice.currency, 'USD');
      expect(invoice.status, 'PAID');
      expect(invoice.planName, 'Pro');
      expect(invoice.planTier, 'PRO');
      expect(invoice.dueAt, DateTime.parse('2026-04-01T00:00:00.000Z'));
      expect(invoice.paidAt, DateTime.parse('2026-04-01T00:00:00.000Z'));
      expect(invoice.createdAt, DateTime.parse('2026-04-01T00:00:00.000Z'));

      expect(invoice.isPaid, isTrue);
      expect(invoice.isOpen, isFalse);
      expect(invoice.isFailed, isFalse);
      expect(invoice.displayStatus, 'Paid');
      expect(invoice.displayAmountDue, r'$9.99');
      expect(invoice.displayAmountPaid, r'$9.99');
      expect(invoice.displayPlanName, 'Pro');
    });

    test('fromJson accepts snake case keys', () {
      final invoice = BillingInvoice.fromJson(
        const <String, dynamic>{
          'id': 'billing-invoice-uuid',
          'invoice_id': 'in_mock_abc123',
          'amount_due_cents': 1999,
          'amount_paid_cents': 1999,
          'currency': 'usd',
          'status': 'paid',
          'plan_name': 'GO+',
          'plan_tier': 'GO_PLUS',
          'due_at': '2026-04-01T00:00:00.000Z',
          'paid_at': '2026-04-02T00:00:00.000Z',
          'created_at': '2026-03-30T00:00:00.000Z',
        },
      );

      expect(invoice.invoiceId, 'in_mock_abc123');
      expect(invoice.amountDueCents, 1999);
      expect(invoice.amountPaidCents, 1999);
      expect(invoice.currency, 'USD');
      expect(invoice.status, 'paid');
      expect(invoice.planName, 'GO+');
      expect(invoice.planTier, 'GO_PLUS');
      expect(invoice.dueAt, DateTime.parse('2026-04-01T00:00:00.000Z'));
      expect(invoice.paidAt, DateTime.parse('2026-04-02T00:00:00.000Z'));
      expect(invoice.createdAt, DateTime.parse('2026-03-30T00:00:00.000Z'));
    });

    test('status helpers detect open and failed states', () {
      final openInvoice = BillingInvoice.fromJson(
        const <String, dynamic>{
          'status': 'OPEN',
        },
      );

      final failedInvoice = BillingInvoice.fromJson(
        const <String, dynamic>{
          'status': 'UNCOLLECTIBLE',
        },
      );

      expect(openInvoice.isOpen, isTrue);
      expect(openInvoice.displayStatus, 'Open');

      expect(failedInvoice.isFailed, isTrue);
      expect(failedInvoice.displayStatus, 'Uncollectible');
    });

    test('displayPlanName falls back to tier names', () {
      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{'planTier': 'PRO'},
        ).displayPlanName,
        'Pro',
      );

      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{'planTier': 'GO_PLUS'},
        ).displayPlanName,
        'GO+',
      );

      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{'planTier': 'FREE'},
        ).displayPlanName,
        'Free',
      );
    });

    test('formats common currencies', () {
      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{
            'currency': 'USD',
            'amountPaidCents': 999,
          },
        ).displayAmountPaid,
        r'$9.99',
      );

      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{
            'currency': 'EUR',
            'amountPaidCents': 999,
          },
        ).displayAmountPaid,
        '€9.99',
      );

      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{
            'currency': 'GBP',
            'amountPaidCents': 999,
          },
        ).displayAmountPaid,
        '£9.99',
      );

      expect(
        BillingInvoice.fromJson(
          const <String, dynamic>{
            'currency': 'EGP',
            'amountPaidCents': 999,
          },
        ).displayAmountPaid,
        '9.99 EGP',
      );
    });

    test('toJson serializes all fields', () {
      final invoice = BillingInvoice(
        id: 'billing-invoice-uuid',
        invoiceId: 'in_mock_abc123',
        amountDueCents: 999,
        amountPaidCents: 999,
        currency: 'USD',
        status: 'PAID',
        planName: 'Pro',
        planTier: 'PRO',
        dueAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
        paidAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
        createdAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
      );

      expect(
        invoice.toJson(),
        <String, dynamic>{
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
        },
      );
    });

    test('copyWith updates selected fields only', () {
      const invoice = BillingInvoice(
        id: 'billing-invoice-uuid',
        invoiceId: 'in_old',
        amountDueCents: 999,
        amountPaidCents: 0,
        status: 'OPEN',
      );

      final updated = invoice.copyWith(
        invoiceId: 'in_new',
        amountPaidCents: 999,
        status: 'PAID',
      );

      expect(updated.id, 'billing-invoice-uuid');
      expect(updated.invoiceId, 'in_new');
      expect(updated.amountDueCents, 999);
      expect(updated.amountPaidCents, 999);
      expect(updated.status, 'PAID');
    });

    test('copyWith clears nullable dates', () {
      final invoice = BillingInvoice(
        dueAt: DateTime.parse('2026-04-01T00:00:00.000Z'),
        paidAt: DateTime.parse('2026-04-02T00:00:00.000Z'),
        createdAt: DateTime.parse('2026-03-30T00:00:00.000Z'),
      );

      final updated = invoice.copyWith(
        clearDueAt: true,
        clearPaidAt: true,
        clearCreatedAt: true,
      );

      expect(updated.dueAt, isNull);
      expect(updated.paidAt, isNull);
      expect(updated.createdAt, isNull);
    });

    test('compares value equality', () {
      const first = BillingInvoice(
        id: 'billing-invoice-uuid',
        invoiceId: 'in_mock_abc123',
        amountPaidCents: 999,
        status: 'PAID',
      );

      const second = BillingInvoice(
        id: 'billing-invoice-uuid',
        invoiceId: 'in_mock_abc123',
        amountPaidCents: 999,
        status: 'PAID',
      );

      const third = BillingInvoice(
        id: 'billing-invoice-uuid',
        invoiceId: 'in_other',
        amountPaidCents: 999,
        status: 'PAID',
      );

      expect(first, second);
      expect(first == third, isFalse);
      expect(first.hashCode, second.hashCode);
    });
  });
}
