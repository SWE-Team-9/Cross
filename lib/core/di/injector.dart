import 'package:get_it/get_it.dart';

import '../../features/upload/data/datasources/audioFilePickerDataSource.dart';
import '../../features/upload/data/repositories/uploadRepositoryImpl.dart';
import '../../features/upload/domain/repositories/uploadRepository.dart';
import '../../features/upload/domain/usecases/pickAudioFileUseCase.dart';
import '../../features/upload/presentation/bloc/uploadPickerCubit.dart';
import '../network/dio_client.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register core services
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerSingleton<DioClient>(
      DioClient(baseUrl: const String.fromEnvironment('API_URL')),
    );
  }

  // Upload feature - T1.11 File Picker
  if (!getIt.isRegistered<AudioFilePickerDataSource>()) {
    getIt.registerLazySingleton<AudioFilePickerDataSource>(
      () => const AudioFilePickerDataSourceImpl(),
    );
  }

  if (!getIt.isRegistered<UploadRepository>()) {
    getIt.registerLazySingleton<UploadRepository>(
      () => UploadRepositoryImpl(getIt<AudioFilePickerDataSource>()),
    );
  }

  if (!getIt.isRegistered<PickAudioFileUseCase>()) {
    getIt.registerLazySingleton<PickAudioFileUseCase>(
      () => PickAudioFileUseCase(getIt<UploadRepository>()),
    );
  }

  if (!getIt.isRegistered<UploadPickerCubit>()) {
    getIt.registerFactory<UploadPickerCubit>(
      () => UploadPickerCubit(getIt<PickAudioFileUseCase>()),
    );
  }

  // Feature dependencies will be added here as we build them
}
