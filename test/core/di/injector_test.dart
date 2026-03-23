import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/profile/data/datasources/profileRemoteDataSource.dart'
    as profile_image_data;
import 'package:soundcloud_clone/features/profile/domain/usecases/uploadProfileImageUseCase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadCubit.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/audioFilePickerDataSource.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/trackManagementRemoteDataSource.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/trackManagementRepository.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/uploadRepository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/deleteTrackUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pickAudioFileUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackMetadataUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackVisibilityUseCase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/trackManagementCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerCubit.dart';

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

      expect(
        getIt.isRegistered<profile_image_data.ProfileRemoteDataSource>(),
        isTrue,
      );
      expect(getIt.isRegistered<UploadProfileImageUseCase>(), isTrue);
      expect(getIt.isRegistered<ProfileImageUploadCubit>(), isTrue);

      final uploadCubit = getIt<UploadPickerCubit>();
      expect(uploadCubit, isA<UploadPickerCubit>());
      await uploadCubit.close();

      final trackCubit = getIt<TrackManagementCubit>();
      expect(trackCubit, isA<TrackManagementCubit>());
      await trackCubit.close();

      final profileImageCubit = getIt<ProfileImageUploadCubit>();
      expect(profileImageCubit, isA<ProfileImageUploadCubit>());
      await profileImageCubit.close();
    });
  });
}