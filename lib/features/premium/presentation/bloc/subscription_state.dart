import 'package:equatable/equatable.dart';

import '../../domain/entities/billing_invoice.dart';
import '../../domain/entities/billing_portal_session.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';

enum SubscriptionStatus {
  initial,
  loading,
  loaded,
  failure,
}

enum SubscriptionActionStatus {
  idle,
  loading,
  success,
  failure,
}

class SubscriptionState extends Equatable {
  final SubscriptionStatus status;
  final SubscriptionActionStatus actionStatus;
  final Subscription subscription;
  final List<Plan> plans;
  final List<BillingInvoice> invoices;
  final BillingPortalSession? billingPortalSession;
  final String? checkoutUrl;
  final String? actionMessage;
  final String? errorMessage;
  final String? actionErrorMessage;

  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.actionStatus = SubscriptionActionStatus.idle,
    this.subscription = const Subscription(),
    this.plans = const <Plan>[],
    this.invoices = const <BillingInvoice>[],
    this.billingPortalSession,
    this.checkoutUrl,
    this.actionMessage,
    this.errorMessage,
    this.actionErrorMessage,
  });

  bool get isInitial => status == SubscriptionStatus.initial;

  bool get isLoading => status == SubscriptionStatus.loading;

  bool get isLoaded => status == SubscriptionStatus.loaded;

  bool get isFailure => status == SubscriptionStatus.failure;

  bool get isActionLoading => actionStatus == SubscriptionActionStatus.loading;

  bool get isActionSuccess => actionStatus == SubscriptionActionStatus.success;

  bool get isActionFailure => actionStatus == SubscriptionActionStatus.failure;

  bool get hasPlans => plans.isNotEmpty;

  bool get hasInvoices => invoices.isNotEmpty;

  bool get hasCheckoutUrl =>
      checkoutUrl != null && checkoutUrl!.trim().isNotEmpty;

  bool get hasBillingPortalSession => billingPortalSession != null;

  bool get canOpenBillingPortal =>
      billingPortalSession != null && billingPortalSession!.hasLaunchUrl;

  bool get isPremium => subscription.isPremium;

  bool get canDownload => subscription.canDownload;

  bool get adsEnabled => subscription.adsEnabled;

  Plan? get currentPlan {
    final currentCode = subscription.normalizedPlanCode;

    for (final plan in plans) {
      if (plan.normalizedCode == currentCode) {
        return plan;
      }
    }

    return null;
  }

  List<Plan> get upgradePlans {
    return plans.where((plan) => plan.isPremium).toList(growable: false);
  }

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionActionStatus? actionStatus,
    Subscription? subscription,
    List<Plan>? plans,
    List<BillingInvoice>? invoices,
    BillingPortalSession? billingPortalSession,
    bool clearBillingPortalSession = false,
    String? checkoutUrl,
    bool clearCheckoutUrl = false,
    String? actionMessage,
    bool clearActionMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionErrorMessage,
    bool clearActionErrorMessage = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      invoices: invoices ?? this.invoices,
      billingPortalSession: clearBillingPortalSession
          ? null
          : billingPortalSession ?? this.billingPortalSession,
      checkoutUrl: clearCheckoutUrl ? null : checkoutUrl ?? this.checkoutUrl,
      actionMessage:
          clearActionMessage ? null : actionMessage ?? this.actionMessage,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      actionErrorMessage: clearActionErrorMessage
          ? null
          : actionErrorMessage ?? this.actionErrorMessage,
    );
  }

  factory SubscriptionState.initial() {
    return const SubscriptionState();
  }

  factory SubscriptionState.loading({
    Subscription previousSubscription = const Subscription(),
    List<Plan> previousPlans = const <Plan>[],
    List<BillingInvoice> previousInvoices = const <BillingInvoice>[],
  }) {
    return SubscriptionState(
      status: SubscriptionStatus.loading,
      subscription: previousSubscription,
      plans: previousPlans,
      invoices: previousInvoices,
    );
  }

  factory SubscriptionState.loaded({
    required Subscription subscription,
    List<Plan> plans = const <Plan>[],
    List<BillingInvoice> invoices = const <BillingInvoice>[],
  }) {
    return SubscriptionState(
      status: SubscriptionStatus.loaded,
      subscription: subscription,
      plans: plans,
      invoices: invoices,
    );
  }

  factory SubscriptionState.failure({
    required String errorMessage,
    Subscription previousSubscription = const Subscription(),
    List<Plan> previousPlans = const <Plan>[],
    List<BillingInvoice> previousInvoices = const <BillingInvoice>[],
  }) {
    return SubscriptionState(
      status: SubscriptionStatus.failure,
      subscription: previousSubscription,
      plans: previousPlans,
      invoices: previousInvoices,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        actionStatus,
        subscription,
        plans,
        invoices,
        billingPortalSession,
        checkoutUrl,
        actionMessage,
        errorMessage,
        actionErrorMessage,
      ];
}
