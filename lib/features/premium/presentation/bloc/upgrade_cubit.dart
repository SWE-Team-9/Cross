import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'upgrade_state.dart';

class UpgradeCubit extends Cubit<UpgradeState> {
  final SubscriptionRepository repository;

  UpgradeCubit(this.repository) : super(const UpgradeState());

  void selectPlan(String plan) => emit(state.copyWith(selectedPlan: plan));

  Future<void> subscribe() async {
    emit(state.copyWith(status: UpgradeStatus.loading));

    try {
      final url = await repository.createCheckout(state.selectedPlan);
      emit(state.copyWith(status: UpgradeStatus.success, checkoutUrl: url));
    } catch (e) {
      emit(state.copyWith(
          status: UpgradeStatus.error, errorMessage: e.toString()));
    }
  }
}
