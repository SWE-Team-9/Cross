import 'package:flutter/widgets.dart';
import '../config/app_config.dart';

// Third-party
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

// Project
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/confirm_email_change_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/is_logged_in_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/request_email_change_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/send_email_verification_usecase.dart';
import '../../features/auth/domain/usecases/verify_email_usecase.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';

// Upload
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

// Profile feature from dev
import '../../features/profile/data/datasources/profile_remote_data_source.dart'
    as profile_data;
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as profile_repo;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as profile_domain;
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';

import '../network/api_constants.dart';
import '../network/dio_client.dart';
import '../services/audio_player_service.dart';
import '../services/implementations/just_audio_player_service.dart';
import '../storage/secure_storage.dart';
import '../../features/social/data/repositories/social_repo.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(
    storage: FileStorage('${appDocDir.path}/.cookies/'),
  );

  // ── Core ───────────────────────────────────────────────────────────────────

  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(aOptions: AndroidOptions()),
    );
  }

  if (!getIt.isRegistered<SecureStorage>()) {
    getIt.registerLazySingleton<SecureStorage>(
      () => SecureStorage(getIt<FlutterSecureStorage>()),
    );
  }

  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(
      () => DioClient(
        baseUrl: ApiConstants.baseUrl,
        secureStorage: getIt<SecureStorage>(),
        cookieJar: cookieJar,
      ),
    );
  }

  if (!getIt.isRegistered<SocialRepo>()) {
    getIt.registerLazySingleton<SocialRepo>(
      () => SocialRepo(getIt<DioClient>().dio),
    );
  }

  // ── Core Services ──────────────────────────────────────────────────────────

  if (!getIt.isRegistered<AudioPlayerService>()) {
    getIt.registerLazySingleton<AudioPlayerService>(
      () => JustAudioPlayerService(),
    );
  }

  // ── Upload Feature: File Picker + Upload Flow ─────────────────────────────

  if (!getIt.isRegistered<AudioFilePickerDataSource>()) {
    getIt.registerLazySingleton<AudioFilePickerDataSource>(
      () => const AudioFilePickerDataSourceImpl(),
    );
  }

  if (!getIt.isRegistered<UploadRepository>()) {
    getIt.registerLazySingleton<UploadRepository>(
      () => UploadRepositoryImpl(
        getIt<AudioFilePickerDataSource>(),
        dioClient: getIt<DioClient>(),
      ),
    );
  }

  if (!getIt.isRegistered<PickAudioFileUseCase>()) {
    getIt.registerLazySingleton<PickAudioFileUseCase>(
      () => PickAudioFileUseCase(getIt<UploadRepository>()),
    );
  }

  if (!getIt.isRegistered<UploadPickerCubit>()) {
    getIt.registerFactory<UploadPickerCubit>(
      () => UploadPickerCubit(
        getIt<PickAudioFileUseCase>(),
        getIt<UploadRepository>(),
      ),
    );
  }

  // ── Upload Feature: Track Management Basics ────────────────────────────────

  const bool useMockTrackManagement = AppConfig.useMockTrackManagement;
  const String mockTrackManagementModeValue = AppConfig.mockTrackManagementMode;

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

  // ── Auth Feature ───────────────────────────────────────────────────────────

  if (!getIt.isRegistered<AuthRemoteDataSource>()) {
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<AuthLocalDataSource>()) {
    getIt.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(getIt<SecureStorage>()),
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

  if (!getIt.isRegistered<RequestEmailChangeUseCase>()) {
    getIt.registerLazySingleton<RequestEmailChangeUseCase>(
      () => RequestEmailChangeUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<ConfirmEmailChangeUseCase>()) {
    getIt.registerLazySingleton<ConfirmEmailChangeUseCase>(
      () => ConfirmEmailChangeUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<AuthCubit>()) {
    getIt.registerFactory<AuthCubit>(
      () => AuthCubit(
        loginUseCase: getIt<LoginUseCase>(),
        registerUseCase: getIt<RegisterUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        isLoggedInUseCase: getIt<IsLoggedInUseCase>(),
        getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
        forgotPasswordUseCase: getIt<ForgotPasswordUseCase>(),
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
        sendEmailVerificationUseCase: getIt<SendEmailVerificationUseCase>(),
        verifyEmailUseCase: getIt<VerifyEmailUseCase>(),
        requestEmailChangeUseCase: getIt<RequestEmailChangeUseCase>(),
        confirmEmailChangeUseCase: getIt<ConfirmEmailChangeUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<RecentlyPlayedCubit>()) {
    getIt.registerLazySingleton<RecentlyPlayedCubit>(
      () => RecentlyPlayedCubit(),
    );
  }

  // ── Profile Feature from dev ───────────────────────────────────────────────

  if (!getIt.isRegistered<profile_data.ProfileRemoteDataSource>()) {
    getIt.registerLazySingleton<profile_data.ProfileRemoteDataSource>(
      () => profile_data.ProfileRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<profile_domain.ProfileRepository>()) {
    getIt.registerLazySingleton<profile_domain.ProfileRepository>(
      () => profile_repo.ProfileRepositoryImpl(
        getIt<profile_data.ProfileRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetProfileUseCase>()) {
    getIt.registerLazySingleton<GetProfileUseCase>(
      () => GetProfileUseCase(getIt<profile_domain.ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateProfileUseCase>()) {
    getIt.registerLazySingleton<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(getIt<profile_domain.ProfileRepository>()),
    );
  }

  if (!getIt.isRegistered<ProfileCubit>()) {
    getIt.registerFactory<ProfileCubit>(
      () => ProfileCubit(
        getProfileUseCase: getIt<GetProfileUseCase>(),
        updateProfileUseCase: getIt<UpdateProfileUseCase>(),
        profileRepository: getIt<profile_domain.ProfileRepository>(),
      ),
    );
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