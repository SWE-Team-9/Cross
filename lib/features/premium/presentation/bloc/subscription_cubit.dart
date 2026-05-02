import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionCubit extends Cubit<Subscription?> {
  final SubscriptionRepository repository;

  SubscriptionCubit(this.repository) : super(null);

  // 🔹 Load current subscription (on app start)
  Future<void> loadSubscription() async {
    final sub = await repository.getMySubscription();
    emit(sub);
  }

  // 🔹 Start upgrade flow (returns checkout URL)
  Future<String> upgrade(String plan) async {
    final checkoutUrl = await repository.createCheckout(plan);
    return checkoutUrl;
  }

  // 🔹 Call after payment success (refresh state)
  Future<void> refreshAfterPayment() async {
    await loadSubscription();
  }

  Future<void> cancel() async {
    await repository.cancelSubscription();
    await loadSubscription();
  }

  Future<void> resume() async {
    await repository.resumeSubscription();
    await loadSubscription();
  }

  Future<void> changePlan(String plan) async {
    await repository.changePlan(plan);
    await loadSubscription();
  }

  Future<String> openBillingPortal() async {
    return await repository.openPortal();
  }
}
