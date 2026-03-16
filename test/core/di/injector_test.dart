import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dependency Injection', () {
    test('AudioPlayerService is registered in GetIt', () {
      // Arrange
      setupDependencies();

      // Act
      final service = getIt<AudioPlayerService>();

      // Assert
      expect(service, isNotNull);
      expect(service, isA<AudioPlayerService>());
    });
  });
}
