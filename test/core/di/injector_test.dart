import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';
import 'package:soundcloud_clone/features/profile/data/datasources/profileRemoteDataSource.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profileRepository.dart';
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

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('Dependency Injection', () {
    test('registers core, upload, track management, and profile dependencies',
        () {
      setupDependencies();

      expect(getIt.isRegistered<FlutterSecureStorage>(), isTrue);
      expect(getIt.isRegistered<SecureStorage>(), isTrue);
      expect(getIt.isRegistered<DioClient>(), isTrue);
      expect(getIt.isRegistered<AudioPlayerService>(), isTrue);

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

      expect(getIt.isRegistered<ProfileRemoteDataSource>(), isTrue);
      expect(getIt.isRegistered<ProfileRepository>(), isTrue);
      expect(getIt.isRegistered<UploadProfileImageUseCase>(), isTrue);
      expect(getIt.isRegistered<ProfileImageUploadCubit>(), isTrue);

      final uploadCubit = getIt<UploadPickerCubit>();
      final trackManagementCubit = getIt<TrackManagementCubit>();
      final profileCubit = getIt<ProfileImageUploadCubit>();

      expect(uploadCubit, isA<UploadPickerCubit>());
      expect(trackManagementCubit, isA<TrackManagementCubit>());
      expect(profileCubit, isA<ProfileImageUploadCubit>());

      uploadCubit.close();
      trackManagementCubit.close();
      profileCubit.close();
    });
  });
}
