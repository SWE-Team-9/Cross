import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';

import '../../fakes/fake_offline_repository.dart';

void main() {
  late OfflineCubit cubit;
  late FakeOfflineRepository repo;

  setUp(() {
    repo = FakeOfflineRepository();
    cubit = OfflineCubit(repo);
  });

  test('initial state is empty', () {
    expect(cubit.state.downloadedTracks, isEmpty);
  });

  test('download adds track to state and persists', () async {
    await cubit.download('t1');

    expect(cubit.isDownloaded('t1'), true);
    expect(cubit.getPath('t1'), '/fake/t1.mp3');

    final saved = await repo.getDownloadedTracks();
    expect(saved.containsKey('t1'), true);
  });

  test('load restores saved tracks', () async {
    await repo.saveDownloadedTracks({'t1': '/fake/t1.mp3'});

    final newCubit = OfflineCubit(repo);

    await Future.delayed(const Duration(milliseconds: 10));

    expect(newCubit.isDownloaded('t1'), true);
  });

  test('download failure throws DOWNLOAD_FAILED', () async {
    final brokenRepo = _BrokenRepo();
    final brokenCubit = OfflineCubit(brokenRepo);

    expect(
      () => brokenCubit.download('t1'),
      throwsException,
    );
  });
}

/// Helper broken repo
class _BrokenRepo extends FakeOfflineRepository {
  @override
  Future<String> downloadTrack(String trackId) async {
    throw Exception('fail');
  }
}
