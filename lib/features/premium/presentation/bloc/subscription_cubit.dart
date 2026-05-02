import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/billing_invoice.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this.repository) : super(SubscriptionState.initial());

  final SubscriptionRepository repository;

  Future<void> loadSubscription() async {
    emit(
      SubscriptionState.loading(
        previousSubscription: state.subscription,
        previousPlans: state.plans,
        previousInvoices: state.invoices,
      ),
    );

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getMySubscription(),
        repository.getPlans(),
      ]);

      emit(
        SubscriptionState.loaded(
          subscription: results[0] as Subscription,
          plans: results[1] as List<Plan>,
          invoices: state.invoices,
        ),
      );
    } catch (error) {
      emit(
        SubscriptionState.failure(
          errorMessage: _readableError(error),
          previousSubscription: state.subscription,
          previousPlans: state.plans,
          previousInvoices: state.invoices,
        ),
      );
    }
  }

  Future<void> loadBilling() async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getMySubscription(),
        repository.getPlans(),
        repository.getInvoices(),
      ]);

      emit(
        state.copyWith(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: results[0] as Subscription,
          plans: results[1] as List<Plan>,
          invoices: results[2] as List<BillingInvoice>,
          actionMessage: 'Billing details loaded.',
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearActionMessage: true,
        ),
      );
    }
  }

  Future<String> upgrade(String plan) async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearCheckoutUrl: true,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final checkoutUrl = await repository.createCheckout(plan);

      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.success,
          checkoutUrl: checkoutUrl,
          actionMessage: 'Checkout session created.',
          clearActionErrorMessage: true,
        ),
      );

      return checkoutUrl;
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearCheckoutUrl: true,
          clearActionMessage: true,
        ),
      );

      rethrow;
    }
  }

  Future<String> subscribe(String plan) async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearCheckoutUrl: true,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final redirectUrl = await repository.subscribe(plan);

      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.success,
          checkoutUrl: redirectUrl,
          actionMessage: 'Subscription request created.',
          clearActionErrorMessage: true,
        ),
      );

      return redirectUrl;
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearCheckoutUrl: true,
          clearActionMessage: true,
        ),
      );

      rethrow;
    }
  }

  Future<void> refreshAfterPayment() async {
    await loadSubscription();
  }

  Future<void> cancel() async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final subscription = await repository.cancelSubscription();

      emit(
        state.copyWith(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: subscription,
          actionMessage: 'Subscription cancellation scheduled.',
          clearActionErrorMessage: true,
        ),
      );

      await _refreshBillingAfterAction();
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearActionMessage: true,
        ),
      );
    }
  }

  Future<void> resume() async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final subscription = await repository.resumeSubscription();

      emit(
        state.copyWith(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: subscription,
          actionMessage: 'Subscription resumed.',
          clearActionErrorMessage: true,
        ),
      );

      await _refreshBillingAfterAction();
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearActionMessage: true,
        ),
      );
    }
  }

  Future<void> changePlan(String plan) async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final subscription = await repository.changePlan(plan);

      emit(
        state.copyWith(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: subscription,
          actionMessage: 'Subscription plan changed.',
          clearActionErrorMessage: true,
        ),
      );

      await _refreshBillingAfterAction();
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearActionMessage: true,
        ),
      );
    }
  }

  Future<String> openBillingPortal() async {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        clearBillingPortalSession: true,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );

    try {
      final session = await repository.openBillingPortalSession();
      final url = session.launchUrl;

      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.success,
          billingPortalSession: session,
          actionMessage: 'Billing portal opened.',
          clearActionErrorMessage: true,
        ),
      );

      return url;
    } catch (error) {
      emit(
        state.copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: _readableError(error),
          clearBillingPortalSession: true,
          clearActionMessage: true,
        ),
      );

      rethrow;
    }
  }

  void clearActionStatus() {
    emit(
      state.copyWith(
        actionStatus: SubscriptionActionStatus.idle,
        clearActionMessage: true,
        clearActionErrorMessage: true,
      ),
    );
  }

  void clearCheckoutUrl() {
    emit(
      state.copyWith(
        clearCheckoutUrl: true,
      ),
    );
  }

  Future<void> _refreshBillingAfterAction() async {
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        repository.getMySubscription(),
        repository.getPlans(),
        repository.getInvoices(),
      ]);

      emit(
        state.copyWith(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: results[0] as Subscription,
          plans: results[1] as List<Plan>,
          invoices: results[2] as List<BillingInvoice>,
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      );
    } catch (_) {
      // Keep the successful action state even if the follow-up refresh fails.
    }
  }

  String _readableError(Object error) {
    final raw = error.toString().trim();

    return raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '')
        .replaceFirst('StateError: ', '');
  }
}