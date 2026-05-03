import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';

void main() {
  group('Plan', () {
    test('fromJson parses free plan from swagger response shape', () {
      final plan = Plan.fromJson(
        const <String, dynamic>{
          'id': 'plan-uuid-free',
          'code': 'FREE',
          'name': 'Free',
          'tier': 'FREE',
          'priceCents': 0,
          'priceDisplay': 'Free',
          'billingInterval': null,
          'uploadLimit': 3,
          'uploadLimitDisplay': '3',
          'isUnlimited': false,
          'trialDays': 0,
          'adsEnabled': true,
          'canDownload': false,
          'supportLevel': 'community',
          'highlightedFeatures': <String>[
            '3 uploads',
            'Standard streaming',
            'Ads supported',
          ],
        },
      );

      expect(plan.id, 'plan-uuid-free');
      expect(plan.code, 'FREE');
      expect(plan.name, 'Free');
      expect(plan.tier, 'FREE');
      expect(plan.priceCents, 0);
      expect(plan.priceDisplay, 'Free');
      expect(plan.billingInterval, isNull);
      expect(plan.uploadLimit, 3);
      expect(plan.uploadLimitDisplay, '3');
      expect(plan.isUnlimited, isFalse);
      expect(plan.trialDays, 0);
      expect(plan.adsEnabled, isTrue);
      expect(plan.canDownload, isFalse);
      expect(plan.supportLevel, 'community');
      expect(
        plan.highlightedFeatures,
        <String>[
          '3 uploads',
          'Standard streaming',
          'Ads supported',
        ],
      );

      expect(plan.isFree, isTrue);
      expect(plan.isPremium, isFalse);
      expect(plan.displayPrice, 'Free');
      expect(plan.displayUploadLimit, '3');
    });

    test('fromJson parses pro plan from swagger response shape', () {
      final plan = Plan.fromJson(
        const <String, dynamic>{
          'id': 'plan-uuid-pro',
          'code': 'PRO',
          'name': 'Pro',
          'tier': 'PRO',
          'priceCents': 999,
          'priceDisplay': r'$9.99/mo',
          'billingInterval': 'MONTHLY',
          'uploadLimit': 100,
          'uploadLimitDisplay': '100',
          'isUnlimited': false,
          'trialDays': 7,
          'adsEnabled': false,
          'canDownload': true,
          'supportLevel': 'priority',
          'highlightedFeatures': <String>[
            '100 uploads',
            'Ad-free',
            'Downloads',
            'Priority support',
          ],
        },
      );

      expect(plan.id, 'plan-uuid-pro');
      expect(plan.code, 'PRO');
      expect(plan.name, 'Pro');
      expect(plan.tier, 'PRO');
      expect(plan.priceCents, 999);
      expect(plan.priceDisplay, r'$9.99/mo');
      expect(plan.billingInterval, 'MONTHLY');
      expect(plan.uploadLimit, 100);
      expect(plan.uploadLimitDisplay, '100');
      expect(plan.isUnlimited, isFalse);
      expect(plan.trialDays, 7);
      expect(plan.adsEnabled, isFalse);
      expect(plan.canDownload, isTrue);
      expect(plan.supportLevel, 'priority');
      expect(
        plan.highlightedFeatures,
        <String>[
          '100 uploads',
          'Ad-free',
          'Downloads',
          'Priority support',
        ],
      );

      expect(plan.isFree, isFalse);
      expect(plan.isPremium, isTrue);
      expect(plan.isPro, isTrue);
      expect(plan.isGoPlus, isFalse);
      expect(plan.displayPrice, r'$9.99/mo');
      expect(plan.displayUploadLimit, '100');
      expect(plan.billingIntervalLabel, 'Monthly');
    });

    test('fromJson parses go plus plan', () {
      final plan = Plan.fromJson(
        const <String, dynamic>{
          'code': 'GO_PLUS',
          'name': 'GO+',
          'tier': 'GO_PLUS',
          'priceCents': 1999,
          'priceDisplay': r'$19.99/mo',
          'billingInterval': 'MONTHLY',
          'uploadLimit': 1000,
          'uploadLimitDisplay': '1000',
          'adsEnabled': false,
          'canDownload': true,
          'supportLevel': 'priority',
        },
      );

      expect(plan.isGoPlus, isTrue);
      expect(plan.isPremium, isTrue);
      expect(plan.displayName, 'GO+');
      expect(plan.displayPrice, r'$19.99/mo');
      expect(plan.displayUploadLimit, '1000');
    });

    test('fromJson accepts snake case keys from alternate backend serializers',
        () {
      final plan = Plan.fromJson(
        const <String, dynamic>{
          'price_cents': 1200,
          'price_display': r'$12/mo',
          'billing_interval': 'MONTHLY',
          'upload_limit': 25,
          'upload_limit_display': '25',
          'is_unlimited': false,
          'trial_days': 14,
          'ads_enabled': false,
          'can_download': true,
          'support_level': 'priority',
          'highlighted_features': <String>['Feature A', 'Feature B'],
        },
      );

      expect(plan.priceCents, 1200);
      expect(plan.priceDisplay, r'$12/mo');
      expect(plan.billingInterval, 'MONTHLY');
      expect(plan.uploadLimit, 25);
      expect(plan.uploadLimitDisplay, '25');
      expect(plan.isUnlimited, isFalse);
      expect(plan.trialDays, 14);
      expect(plan.adsEnabled, isFalse);
      expect(plan.canDownload, isTrue);
      expect(plan.supportLevel, 'priority');
      expect(plan.highlightedFeatures, <String>['Feature A', 'Feature B']);
    });

    test('supports unlimited upload display', () {
      final plan = Plan.fromJson(
        const <String, dynamic>{
          'code': 'PRO',
          'name': 'Pro',
          'isUnlimited': true,
          'uploadLimit': 0,
          'uploadLimitDisplay': '',
        },
      );

      expect(plan.displayUploadLimit, 'Unlimited');
    });

    test('falls back to formatted price when priceDisplay is missing', () {
      final monthlyPlan = Plan.fromJson(
        const <String, dynamic>{
          'priceCents': 999,
          'billingInterval': 'MONTHLY',
        },
      );

      final yearlyPlan = Plan.fromJson(
        const <String, dynamic>{
          'priceCents': 12000,
          'billingInterval': 'YEARLY',
        },
      );

      expect(monthlyPlan.displayPrice, r'$9.99/mo');
      expect(yearlyPlan.displayPrice, r'$120');
    });

    test('keeps legacy fields compatible with old callers', () {
      final plan = Plan.fromJson(
        const <String, dynamic>{
          'priceCents': 999,
          'billingInterval': 'MONTHLY',
          'highlightedFeatures': <String>[
            'Ad-free',
            'Downloads',
          ],
        },
      );

      expect(plan.price, 9.99);
      expect(plan.interval, 'month');
      expect(plan.description, 'Ad-free • Downloads');
    });

    test('toJson serializes all fields', () {
      const plan = Plan(
        id: 'plan-1',
        code: 'PRO',
        name: 'Pro',
        tier: 'PRO',
        priceCents: 999,
        priceDisplay: r'$9.99/mo',
        billingInterval: 'MONTHLY',
        uploadLimit: 100,
        uploadLimitDisplay: '100',
        isUnlimited: false,
        trialDays: 7,
        adsEnabled: false,
        canDownload: true,
        supportLevel: 'priority',
        highlightedFeatures: <String>['Ad-free'],
        price: 9.99,
        description: 'Ad-free',
        interval: 'month',
      );

      expect(
        plan.toJson(),
        <String, dynamic>{
          'id': 'plan-1',
          'code': 'PRO',
          'name': 'Pro',
          'tier': 'PRO',
          'priceCents': 999,
          'priceDisplay': r'$9.99/mo',
          'billingInterval': 'MONTHLY',
          'uploadLimit': 100,
          'uploadLimitDisplay': '100',
          'isUnlimited': false,
          'trialDays': 7,
          'adsEnabled': false,
          'canDownload': true,
          'supportLevel': 'priority',
          'highlightedFeatures': <String>['Ad-free'],
          'price': 9.99,
          'description': 'Ad-free',
          'interval': 'month',
        },
      );
    });

    test('copyWith updates selected fields only', () {
      const original = Plan(
        id: 'plan-1',
        code: 'FREE',
        name: 'Free',
        tier: 'FREE',
        uploadLimit: 3,
        adsEnabled: true,
      );

      final updated = original.copyWith(
        code: 'PRO',
        name: 'Pro',
        tier: 'PRO',
        uploadLimit: 100,
        adsEnabled: false,
        canDownload: true,
      );

      expect(updated.id, 'plan-1');
      expect(updated.code, 'PRO');
      expect(updated.name, 'Pro');
      expect(updated.tier, 'PRO');
      expect(updated.uploadLimit, 100);
      expect(updated.adsEnabled, isFalse);
      expect(updated.canDownload, isTrue);
    });

    test('copyWith can clear billing interval', () {
      const original = Plan(
        billingInterval: 'MONTHLY',
      );

      final updated = original.copyWith(clearBillingInterval: true);

      expect(updated.billingInterval, isNull);
    });

    test('compares value equality including highlighted features', () {
      const first = Plan(
        code: 'PRO',
        highlightedFeatures: <String>['Ad-free', 'Downloads'],
      );

      const second = Plan(
        code: 'PRO',
        highlightedFeatures: <String>['Ad-free', 'Downloads'],
      );

      const third = Plan(
        code: 'PRO',
        highlightedFeatures: <String>['Ad-free'],
      );

      expect(first, second);
      expect(first == third, isFalse);
      expect(first.hashCode, second.hashCode);
    });
  });
}
