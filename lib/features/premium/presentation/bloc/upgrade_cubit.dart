import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import 'upgrade_state.dart';

class UpgradeCubit extends Cubit<UpgradeState> {
  final SubscriptionRepository repository;

  UpgradeCubit(this.repository) : super(const UpgradeState());

  // 🔹 Change selected plan (PRO / GO+ later)
  void selectPlan(String plan) {
    emit(state.copyWith(selectedPlan: plan));
  }

  // 🔹 Simulate subscription
  Future<void> subscribe() async {
    emit(state.copyWith(status: UpgradeStatus.loading));

    try {
      final Subscription result =
          await repository.subscribe(state.selectedPlan);

      if (result.subscriptionType == state.selectedPlan) {
        emit(state.copyWith(status: UpgradeStatus.success));
      } else {
        emit(state.copyWith(
          status: UpgradeStatus.error,
          errorMessage: 'Subscription failed',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: UpgradeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
