import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

// import '../../features/auth/data/datasources/auth_local_data_source.dart';
// import '../../features/auth/data/datasources/auth_remote_data_source.dart';
// import '../../features/auth/data/repositories/auth_repository_impl.dart';
// import '../../features/auth/domain/repositories/auth_repository.dart';
// import '../../features/auth/domain/usecases/check_email_exists_usecase.dart';
// import '../../features/auth/domain/usecases/complete_profile_usecase.dart';
// import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
// import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
// import '../../features/auth/domain/usecases/is_logged_in_usecase.dart';
// import '../../features/auth/domain/usecases/login_usecase.dart';
// import '../../features/auth/domain/usecases/logout_usecase.dart';
// import '../../features/auth/domain/usecases/register_usecase.dart';
// import '../../features/auth/domain/usecases/reset_password_usecase.dart';
// import '../../features/auth/domain/usecases/send_email_verification_usecase.dart';
// import '../../features/auth/domain/usecases/verify_email_usecase.dart';
// import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/upload/data/datasources/audioFilePickerDataSource.dart';
import '../../features/upload/data/repositories/uploadRepositoryImpl.dart';
import '../../features/upload/domain/repositories/uploadRepository.dart';
import '../../features/upload/domain/usecases/pickAudioFileUseCase.dart';
import '../../features/upload/presentation/bloc/uploadPickerCubit.dart';
import '../network/dio_client.dart';
import '../services/audio_player_service.dart';
import '../services/implementations/just_audio_player_service.dart';
import '../storage/secure_storage.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Core storage
  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }

  if (!getIt.isRegistered<SecureStorage>()) {
    getIt.registerLazySingleton<SecureStorage>(
      () => SecureStorage(getIt<FlutterSecureStorage>()),
    );
  }

  // Core networking
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(
      () => DioClient(
        baseUrl: const String.fromEnvironment(
          'API_URL',
          defaultValue:
              'https://ae735f51-ad9b-4187-bd88-52986fa6b324.mock.pstmn.io',
        ),
        secureStorage: getIt<SecureStorage>(),
      ),
    );
  }

  // Core services
  if (!getIt.isRegistered<AudioPlayerService>()) {
    getIt.registerLazySingleton<AudioPlayerService>(
      () => JustAudioPlayerService(),
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

  // getIt.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(getIt<DioClient>()),
  // );

  // getIt.registerLazySingleton<AuthLocalDataSource>(
  //   () => AuthLocalDataSourceImpl(getIt<SecureStorage>()),
  // );

  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remoteDataSource: getIt<AuthRemoteDataSource>(),
  //     localDataSource: getIt<AuthLocalDataSource>(),
  //   ),
  // );

  // getIt.registerLazySingleton<CheckEmailExistsUseCase>(
  //   () => CheckEmailExistsUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<LoginUseCase>(
  //   () => LoginUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<RegisterUseCase>(
  //   () => RegisterUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<CompleteProfileUseCase>(
  //   () => CompleteProfileUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<LogoutUseCase>(
  //   () => LogoutUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<IsLoggedInUseCase>(
  //   () => IsLoggedInUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<GetCurrentUserUseCase>(
  //   () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<ForgotPasswordUseCase>(
  //   () => ForgotPasswordUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<ResetPasswordUseCase>(
  //   () => ResetPasswordUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<SendEmailVerificationUseCase>(
  //   () => SendEmailVerificationUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerLazySingleton<VerifyEmailUseCase>(
  //   () => VerifyEmailUseCase(getIt<AuthRepository>()),
  // );

  // getIt.registerFactory<AuthCubit>(
  //   () => AuthCubit(
  //     checkEmailExistsUseCase: getIt<CheckEmailExistsUseCase>(),
  //     loginUseCase: getIt<LoginUseCase>(),
  //     registerUseCase: getIt<RegisterUseCase>(),
  //     completeProfileUseCase: getIt<CompleteProfileUseCase>(),
  //     logoutUseCase: getIt<LogoutUseCase>(),
  //     isLoggedInUseCase: getIt<IsLoggedInUseCase>(),
  //     getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
  //     forgotPasswordUseCase: getIt<ForgotPasswordUseCase>(),
  //     resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
  //     sendEmailVerificationUseCase: getIt<SendEmailVerificationUseCase>(),
  //     verifyEmailUseCase: getIt<VerifyEmailUseCase>(),
  //   ),
  // );
}
