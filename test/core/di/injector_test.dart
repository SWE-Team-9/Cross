import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );

    await getIt.reset();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await getIt.reset();
  });

  group('Dependency Injection', () {
    test('AudioPlayerService is registered in GetIt', () async {
      await setupDependencies();

      final service = getIt<AudioPlayerService>();

      expect(service, isNotNull);
      expect(service, isA<AudioPlayerService>());
    });

    test(
        'setupDependencies registers core, upload, track management, and profile dependencies',
        () async {
      await setupDependencies();

      expect(getIt.isRegistered<DioClient>(), isTrue);

      expect(getIt.isRegistered<AudioFilePickerDataSource>(), isTrue);
      expect(getIt.isRegistered<UploadRepository>(), isTrue);
      expect(getIt.isRegistered<PickAudioFileUseCase>(), isTrue);
      expect(getIt.isRegistered<UploadPickerCubit>(), isTrue);

      expect(getIt.isRegistered<TrackManagementRemoteDataSource>(), isTrue);
      expect(getIt.isRegistered<TrackManagementRepository>(), isTrue);
      expect(getIt.isRegistered<UpdateTrackMetadataUseCase>(), isTrue);
      expect(getIt.isRegistered<UpdateTrackVisibilityUseCase>(), isTrue);
      expect(getIt.isRegistered<DeleteTrackUseCase>(), isTrue);
      expect(getIt.isRegistered<TrackManagementCubit>(), isTrue);

      final uploadCubit = getIt<UploadPickerCubit>();
      expect(uploadCubit, isA<UploadPickerCubit>());
      await uploadCubit.close();

      final trackCubit = getIt<TrackManagementCubit>();
      expect(trackCubit, isA<TrackManagementCubit>());
      await trackCubit.close();
    });
  });
}
