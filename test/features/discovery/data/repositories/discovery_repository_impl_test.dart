import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/discovery/data/datasources/discovery_remote_data_source.dart';
import 'package:soundcloud_clone/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:soundcloud_clone/features/discovery/data/dto/resolved_resource_model.dart';
import 'package:soundcloud_clone/features/discovery/domain/entities/resolved_resource.dart';

class MockDiscoveryRemoteDataSource extends Mock
    implements DiscoveryRemoteDataSource {}

void main() {
  late MockDiscoveryRemoteDataSource remote;
  late DiscoveryRepositoryImpl repository;

  setUp(() {
    remote = MockDiscoveryRemoteDataSource();
    repository = DiscoveryRepositoryImpl(remote);
  });

  test('resolveUrl caches repeated requests for the same trimmed URL', () async {
    const url = 'https://api.test/ali/track-slug';
    final resolved = ResolvedResourceModel(
      matched: true,
      type: ResolvedResourceType.track,
      resourceId: 'trk_123',
      slug: 'track-slug',
    );

    when(() => remote.resolveUrl(url)).thenAnswer((_) async => resolved);

    final first = await repository.resolveUrl('  $url  ');
    final second = await repository.resolveUrl(url);

    expect(first, equals(second));
    verify(() => remote.resolveUrl(url)).called(1);
  });
}
