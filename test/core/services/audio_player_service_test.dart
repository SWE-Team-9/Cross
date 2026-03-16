import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/services/implementations/just_audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JustAudioPlayerService', () {
    late JustAudioPlayerService service;

    setUp(() {
      service = JustAudioPlayerService();
    });

    test('service can be created', () {
      expect(service, isNotNull);
    });

    test('pause and stop can be called', () async {
      await service.pause();
      await service.stop();
    });

    test('seek works', () async {
      await service.seek(const Duration(seconds: 10));
    });

    test('dispose does not crash', () async {
      await service.dispose();
    });
  });
}
