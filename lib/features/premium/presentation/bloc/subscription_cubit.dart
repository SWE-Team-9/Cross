// Minimal stub for SubscriptionCubit to keep references valid.
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionCubit extends Cubit<Subscription?> {
  final SubscriptionRepository repository;

  SubscriptionCubit(this.repository) : super(const Subscription());

  Future<void> loadSubscription() async {
    final sub = await repository.getMySubscription();
    emit(sub);
  }

  Future<String> upgrade(String plan) async {
    return await repository.createCheckout(plan);
  }

  Future<void> refreshAfterPayment() async => await loadSubscription();

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

  Future<String> openBillingPortal() async => await repository.openPortal();
}
