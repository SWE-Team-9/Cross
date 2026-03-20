import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_email_exists_usecase.dart';
import '../../features/auth/domain/usecases/complete_profile_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/is_logged_in_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/send_email_verification_usecase.dart';
import '../../features/auth/domain/usecases/verify_email_usecase.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/profile/data/datasources/profileRemoteDataSource.dart';
import '../../features/profile/data/repositories/profileRepositoryFake.dart';
import '../../features/profile/data/repositories/profileRepositoryImpl.dart';
import '../../features/profile/domain/repositories/profileRepository.dart';
import '../../features/profile/domain/usecases/uploadProfileImageUseCase.dart';
import '../../features/profile/presentation/bloc/profileImageUploadCubit.dart';
import '../../features/upload/data/datasources/audioFilePickerDataSource.dart';
import '../../features/upload/data/datasources/trackManagementRemoteDataSource.dart';
import '../../features/upload/data/repositories/trackManagementRepositoryFake.dart';
import '../../features/upload/data/repositories/trackManagementRepositoryImpl.dart';
import '../../features/upload/data/repositories/uploadRepositoryImpl.dart';
import '../../features/upload/domain/repositories/trackManagementRepository.dart';
import '../../features/upload/domain/repositories/uploadRepository.dart';
import '../../features/upload/domain/usecases/deleteTrackUseCase.dart';
import '../../features/upload/domain/usecases/pickAudioFileUseCase.dart';
import '../../features/upload/domain/usecases/updateTrackMetadataUseCase.dart';
import '../../features/upload/domain/usecases/updateTrackVisibilityUseCase.dart';
import '../../features/upload/presentation/bloc/trackManagementCubit.dart';
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

  // Upload feature - T2.8 Track Management Basics
  const bool useMockTrackManagement = bool.fromEnvironment(
    'USE_MOCK_TRACK_MANAGEMENT',
    defaultValue: false,
  );

  const String mockTrackManagementModeValue = String.fromEnvironment(
    'MOCK_TRACK_MANAGEMENT_MODE',
    defaultValue: 'success',
  );

  final MockTrackManagementMode mockTrackManagementMode =
      _parseMockTrackManagementMode(mockTrackManagementModeValue);

  if (!getIt.isRegistered<TrackManagementRemoteDataSource>()) {
    getIt.registerLazySingleton<TrackManagementRemoteDataSource>(
      () => TrackManagementRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<TrackManagementRepository>()) {
    getIt.registerLazySingleton<TrackManagementRepository>(
      () => useMockTrackManagement
          ? TrackManagementRepositoryFake(
              mode: mockTrackManagementMode,
            )
          : TrackManagementRepositoryImpl(
              getIt<TrackManagementRemoteDataSource>(),
            ),
    );
  }

  if (!getIt.isRegistered<UpdateTrackMetadataUseCase>()) {
    getIt.registerLazySingleton<UpdateTrackMetadataUseCase>(
      () => UpdateTrackMetadataUseCase(getIt<TrackManagementRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateTrackVisibilityUseCase>()) {
    getIt.registerLazySingleton<UpdateTrackVisibilityUseCase>(
      () => UpdateTrackVisibilityUseCase(getIt<TrackManagementRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteTrackUseCase>()) {
    getIt.registerLazySingleton<DeleteTrackUseCase>(
      () => DeleteTrackUseCase(getIt<TrackManagementRepository>()),
    );
  }

  if (!getIt.isRegistered<TrackManagementCubit>()) {
    getIt.registerFactory<TrackManagementCubit>(
      () => TrackManagementCubit(
        getIt<UpdateTrackMetadataUseCase>(),
        getIt<UpdateTrackVisibilityUseCase>(),
        getIt<DeleteTrackUseCase>(),
      ),
    );
  }

  // Profile feature - T2.7 Profile Image Upload Flow
  const bool useMockProfileImageUpload = bool.fromEnvironment(
    'USE_MOCK_PROFILE_IMAGE_UPLOAD',
    defaultValue: false,
  );

  const String mockProfileImageUploadModeValue = String.fromEnvironment(
    'MOCK_PROFILE_IMAGE_UPLOAD_MODE',
    defaultValue: 'success',
  );

  final MockProfileImageUploadMode mockProfileImageUploadMode =
      _parseMockProfileImageUploadMode(mockProfileImageUploadModeValue);

  if (!getIt.isRegistered<ProfileRemoteDataSource>()) {
    getIt.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => useMockProfileImageUpload
          ? ProfileRepositoryFake(
              mode: mockProfileImageUploadMode,
            )
          : ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<UploadProfileImageUseCase>()) {
    getIt.registerLazySingleton<UploadProfileImageUseCase>(
      () => UploadProfileImageUseCase(getIt<ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<ProfileImageUploadCubit>()) {
    getIt.registerFactory<ProfileImageUploadCubit>(
      () => ProfileImageUploadCubit(getIt<UploadProfileImageUseCase>()),
    );
  }

  // Auth feature
  if (!getIt.isRegistered<AuthRemoteDataSource>()) {
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<AuthLocalDataSource>()) {
    getIt.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(getIt<FlutterSecureStorage>()),
    );
  }

  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        localDataSource: getIt<AuthLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<CheckEmailExistsUseCase>()) {
    getIt.registerLazySingleton<CheckEmailExistsUseCase>(
      () => CheckEmailExistsUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<RegisterUseCase>()) {
    getIt.registerLazySingleton<RegisterUseCase>(
      () => RegisterUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<CompleteProfileUseCase>()) {
    getIt.registerLazySingleton<CompleteProfileUseCase>(
      () => CompleteProfileUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LogoutUseCase>()) {
    getIt.registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<IsLoggedInUseCase>()) {
    getIt.registerLazySingleton<IsLoggedInUseCase>(
      () => IsLoggedInUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<GetCurrentUserUseCase>()) {
    getIt.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<ForgotPasswordUseCase>()) {
    getIt.registerLazySingleton<ForgotPasswordUseCase>(
      () => ForgotPasswordUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<ResetPasswordUseCase>()) {
    getIt.registerLazySingleton<ResetPasswordUseCase>(
      () => ResetPasswordUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<SendEmailVerificationUseCase>()) {
    getIt.registerLazySingleton<SendEmailVerificationUseCase>(
      () => SendEmailVerificationUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<VerifyEmailUseCase>()) {
    getIt.registerLazySingleton<VerifyEmailUseCase>(
      () => VerifyEmailUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<AuthCubit>()) {
    getIt.registerFactory<AuthCubit>(
      () => AuthCubit(
        checkEmailExistsUseCase: getIt<CheckEmailExistsUseCase>(),
        loginUseCase: getIt<LoginUseCase>(),
        registerUseCase: getIt<RegisterUseCase>(),
        completeProfileUseCase: getIt<CompleteProfileUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        isLoggedInUseCase: getIt<IsLoggedInUseCase>(),
        getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
        forgotPasswordUseCase: getIt<ForgotPasswordUseCase>(),
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
        sendEmailVerificationUseCase: getIt<SendEmailVerificationUseCase>(),
        verifyEmailUseCase: getIt<VerifyEmailUseCase>(),
      ),
    );
  }
}

MockProfileImageUploadMode _parseMockProfileImageUploadMode(String value) {
  switch (value.toLowerCase()) {
    case 'alwaysfail':
      return MockProfileImageUploadMode.alwaysFail;
    case 'failonce':
      return MockProfileImageUploadMode.failOnce;
    case 'success':
    default:
      return MockProfileImageUploadMode.success;
  }
}

MockTrackManagementMode _parseMockTrackManagementMode(String value) {
  switch (value.toLowerCase()) {
    case 'alwaysfail':
      return MockTrackManagementMode.alwaysFail;
    case 'failonce':
      return MockTrackManagementMode.failOnce;
    case 'success':
    default:
      return MockTrackManagementMode.success;
  }
}
