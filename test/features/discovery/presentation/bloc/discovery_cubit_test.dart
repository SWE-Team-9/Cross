import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/discovery/domain/entities/resolved_resource.dart';
import 'package:soundcloud_clone/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:soundcloud_clone/features/discovery/domain/usecases/resolve_resource_usecase.dart';
import 'package:soundcloud_clone/features/discovery/presentation/bloc/discovery_cubit.dart';

class FakeDiscoveryRepository implements DiscoveryRepository {
  ResolvedResource? result;
  Object? error;
  final calls = <String>[];

  @override
  Future<ResolvedResource> resolveUrl(String url) async {
    calls.add(url);

    if (error != null) throw error!;

    return result ??
        const ResolvedResource(
          matched: false,
          type: ResolvedResourceType.unknown,
          resourceId: '',
        );
  }
}

void main() {
  late FakeDiscoveryRepository repository;
  late ResolveResourceUseCase useCase;

  setUp(() {
    repository = FakeDiscoveryRepository();
    useCase = ResolveResourceUseCase(repository);
  });

  DiscoveryCubit buildCubit() => DiscoveryCubit(useCase);

  group('DiscoveryCubit', () {
    test('initial state is DiscoveryInitial', () {
      final cubit = buildCubit();

      expect(cubit.state, const DiscoveryInitial());

      cubit.close();
    });

    blocTest<DiscoveryCubit, DiscoveryState>(
      'does nothing when url is empty',
      build: buildCubit,
      act: (cubit) => cubit.resolve('   '),
      expect: () => <DiscoveryState>[],
      verify: (_) {
        expect(repository.calls, isEmpty);
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'emits loading then resolved when resolver succeeds',
      build: () {
        repository.result = const ResolvedResource(
          matched: true,
          type: ResolvedResourceType.track,
          resourceId: 'trk_123',
          slug: 'track-slug',
        );

        return buildCubit();
      },
      act: (cubit) => cubit.resolve('https://dev.iqa3.tech/ali/track-slug'),
      expect: () => [
        const DiscoveryLoading(),
        const DiscoveryResolved(
          ResolvedResource(
            matched: true,
            type: ResolvedResourceType.track,
            resourceId: 'trk_123',
            slug: 'track-slug',
          ),
        ),
      ],
      verify: (_) {
        expect(
          repository.calls,
          ['https://dev.iqa3.tech/ali/track-slug'],
        );
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'trims url before resolving',
      build: () {
        repository.result = const ResolvedResource(
          matched: true,
          type: ResolvedResourceType.playlist,
          resourceId: 'pl_123',
        );

        return buildCubit();
      },
      act: (cubit) => cubit.resolve('  https://dev.iqa3.tech/ali/playlist  '),
      verify: (_) {
        expect(
          repository.calls,
          ['https://dev.iqa3.tech/ali/playlist'],
        );
      },
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'emits loading then error when resolver throws',
      build: () {
        repository.error = Exception('resolver failed');
        return buildCubit();
      },
      act: (cubit) => cubit.resolve('https://dev.iqa3.tech/bad-link'),
      expect: () => [
        const DiscoveryLoading(),
        isA<DiscoveryError>().having(
          (state) => state.message,
          'message',
          contains('resolver failed'),
        ),
      ],
    );

    blocTest<DiscoveryCubit, DiscoveryState>(
      'reset emits initial state',
      build: buildCubit,
      act: (cubit) => cubit.reset(),
      expect: () => [
        const DiscoveryInitial(),
      ],
    );
  });
}
