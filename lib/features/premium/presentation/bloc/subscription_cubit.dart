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

  // 🔹 Upgrade (called after successful payment)
  Future<void> upgrade(String plan) async {
    final sub = await repository.subscribe(plan);
    emit(sub);
  }
}
