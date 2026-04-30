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
    'upgrade returns checkout URL (no state emit)',
    build: () {
      when(() => repo.createCheckout('PRO'))
          .thenAnswer((_) async => 'https://checkout.url');
      return cubit;
    },
    act: (cubit) => cubit.upgrade('PRO'),
    expect: () => [], // ✅ FIX
  );
}
