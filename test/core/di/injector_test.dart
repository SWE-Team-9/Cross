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
import 'package:soundcloud_clone/features/upload/domain/repositories/uploadRepository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pickAudioFileUseCase.dart';
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
    test('registers core, upload, and profile dependencies', () {
      setupDependencies();

      expect(getIt.isRegistered<FlutterSecureStorage>(), isTrue);
      expect(getIt.isRegistered<SecureStorage>(), isTrue);
      expect(getIt.isRegistered<DioClient>(), isTrue);
      expect(getIt.isRegistered<AudioPlayerService>(), isTrue);

      expect(getIt.isRegistered<AudioFilePickerDataSource>(), isTrue);
      expect(getIt.isRegistered<UploadRepository>(), isTrue);
      expect(getIt.isRegistered<PickAudioFileUseCase>(), isTrue);
      expect(getIt.isRegistered<UploadPickerCubit>(), isTrue);

      expect(getIt.isRegistered<ProfileRemoteDataSource>(), isTrue);
      expect(getIt.isRegistered<ProfileRepository>(), isTrue);
      expect(getIt.isRegistered<UploadProfileImageUseCase>(), isTrue);
      expect(getIt.isRegistered<ProfileImageUploadCubit>(), isTrue);

      final uploadCubit = getIt<UploadPickerCubit>();
      final profileCubit = getIt<ProfileImageUploadCubit>();

      expect(uploadCubit, isA<UploadPickerCubit>());
      expect(profileCubit, isA<ProfileImageUploadCubit>());

      uploadCubit.close();
      profileCubit.close();
    });
  });
}
