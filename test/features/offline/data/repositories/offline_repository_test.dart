import 'package:flutter_test/flutter_test.dart';
import '../../fakes/fake_offline_repository.dart';

void main() {
  late FakeOfflineRepository repo;

  setUp(() {
    repo = FakeOfflineRepository();
  });

  test('downloadTrack stores file path', () async {
    final path = await repo.downloadTrack('t1');

    expect(path, '/fake/t1.mp3');

    final stored = await repo.getDownloadedTracks();
    expect(stored['t1'], '/fake/t1.mp3');
  });

  test('saveDownloadedTracks persists data', () async {
    await repo.saveDownloadedTracks({
      't1': '/fake/t1.mp3',
    });

    final stored = await repo.getDownloadedTracks();

    expect(stored.length, 1);
    expect(stored['t1'], '/fake/t1.mp3');
  });

  test('getDownloadedTracks returns empty if nothing saved', () async {
    final stored = await repo.getDownloadedTracks();
    expect(stored, isEmpty);
  });
}
