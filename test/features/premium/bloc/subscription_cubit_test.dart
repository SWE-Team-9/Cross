import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository repo;
  late SubscriptionCubit cubit;

  setUp(() {
    repo = MockSubscriptionRepository();
    cubit = SubscriptionCubit(repo);
  });

  final freeSub = const Subscription(
    subscriptionType: 'FREE',
    uploadLimit: 3,
    uploadedTracks: 3,
    remainingUploads: 0,
  );

  final proSub = const Subscription(
    subscriptionType: 'PRO',
    uploadLimit: 1000,
    uploadedTracks: 2,
    remainingUploads: 998,
  );

  blocTest<SubscriptionCubit, Subscription?>(
    'loads FREE subscription on init',
    build: () {
      when(() => repo.getMySubscription()).thenAnswer((_) async => freeSub);
      return cubit;
    },
    act: (cubit) => cubit.loadSubscription(),
    expect: () => [freeSub],
  );

  blocTest<SubscriptionCubit, Subscription?>(
    'upgrades to PRO',
    build: () {
      when(() => repo.subscribe('PRO')).thenAnswer((_) async => proSub);
      return cubit;
    },
    act: (cubit) => cubit.upgrade('PRO'),
    expect: () => [proSub],
  );
}
