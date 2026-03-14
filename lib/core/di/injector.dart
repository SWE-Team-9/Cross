import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../services/audio_player_service.dart';
import '../services/implementations/just_audio_player_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register core services
  getIt.registerSingleton<DioClient>(
    DioClient(baseUrl: const String.fromEnvironment('API_URL')),
  );

  // Register audio player service
  getIt.registerLazySingleton<AudioPlayerService>(
    () => JustAudioPlayerService(),
  );

  // Feature dependencies will be added here as we build them
}
