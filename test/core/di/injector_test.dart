import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';

import 'package:soundcloud_clone/main.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/services/implementations/just_audio_player_service.dart';

import 'package:soundcloud_clone/features/upload/data/datasources/audio_file_picker_data_source.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_management_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/track_management_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/upload_repository.dart';

import 'package:soundcloud_clone/features/upload/domain/usecases/delete_track_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pick_audi_file_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_metadata_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_visibility_usecase.dart';

import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';

class FakeAudioHandler extends BaseAudioHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    audioHandler = FakeAudioHandler();
  });

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async => '.',
    );

    await getIt.reset();

    // 🔥 Inject handler into service
    getIt.registerLazySingleton<AudioPlayerService>(
      () => JustAudioPlayerService(handler: audioHandler),
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);

    await getIt.reset();
  });

  group('Dependency Injection', () {
    test('AudioPlayerService is registered', () {
      final service = getIt<AudioPlayerService>();
      expect(service, isNotNull);
    });

    test('All dependencies are registered', () async {
      await setupDependencies();

      expect(getIt.isRegistered<DioClient>(), true);
      expect(getIt.isRegistered<AudioFilePickerDataSource>(), true);
      expect(getIt.isRegistered<UploadRepository>(), true);
      expect(getIt.isRegistered<PickAudioFileUseCase>(), true);
      expect(getIt.isRegistered<UploadPickerCubit>(), true);

      expect(getIt.isRegistered<TrackManagementRemoteDataSource>(), true);
      expect(getIt.isRegistered<TrackManagementRepository>(), true);
      expect(getIt.isRegistered<UpdateTrackMetadataUseCase>(), true);
      expect(getIt.isRegistered<UpdateTrackVisibilityUseCase>(), true);
      expect(getIt.isRegistered<DeleteTrackUseCase>(), true);
      expect(getIt.isRegistered<TrackManagementCubit>(), true);
    });
  });
}
