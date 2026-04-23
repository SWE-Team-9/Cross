import 'package:flutter/widgets.dart';
import '../config/app_config.dart';

// Third-party
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/data/datasources/recently_played_remote_datasource.dart';
import 'package:soundcloud_clone/features/recently_played/data/repositories/recently_played_repository_impl.dart';
import 'package:soundcloud_clone/features/recently_played/domain/usecases/get_recently_played.dart';

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

// Playback
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';

// Upload
import '../../features/upload/data/datasources/audio_file_picker_data_source.dart';
import '../../features/upload/data/datasources/track_management_remote_data_source.dart';
import '../../features/upload/data/repositories/track_management_repository_fake.dart';
import '../../features/upload/data/repositories/track_management_repository_impl.dart';
import '../../features/upload/data/repositories/upload_repository_impl.dart';
import '../../features/upload/domain/repositories/track_management_repository.dart';
import '../../features/upload/domain/repositories/upload_repository.dart';
import '../../features/upload/domain/usecases/delete_track_usecase.dart';
import '../../features/upload/domain/usecases/pick_audi_file_usecase.dart';
import '../../features/upload/domain/usecases/update_track_metadata_usecase.dart';
import '../../features/upload/domain/usecases/update_track_visibility_usecase.dart';
import '../../features/upload/presentation/bloc/track_management_cubit.dart';
import '../../features/upload/presentation/bloc/upload_picker_cubit.dart';
import '../../features/upload/data/services/audio_picker_permission_service.dart';
import '../../features/upload/data/datasources/track_status_remote_data_source.dart';
import '../../features/upload/data/repositories/track_status_repository_impl.dart';
import '../../features/upload/domain/repositories/i_track_status_repository.dart';
import '../../features/upload/domain/usecases/watch_track_processing_status_use_case.dart';

// Profile feature
import '../../features/profile/data/datasources/profile_remote_data_source.dart'
    as profile_data;
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as profile_repo;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as profile_domain;
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';

// Social existing
import '../../features/social/data/repositories/social_repo.dart';

// Interactions
import '../../features/interactions/data/datasources/interactions_remote_data_source.dart';
import '../../features/interactions/data/repositories/interactions_repository_impl.dart';
import '../../features/interactions/domain/repositories/interactions_repository.dart';
import '../../features/interactions/domain/usecases/get_track_interaction_status_usecase.dart';
import '../../features/interactions/domain/usecases/like_track_usecase.dart';
import '../../features/interactions/domain/usecases/repost_track_usecase.dart';
import '../../features/interactions/domain/usecases/unlike_track_usecase.dart';
import '../../features/interactions/domain/usecases/unrepost_track_usecase.dart';
import '../../features/interactions/presentation/bloc/track_interaction_cubit.dart';
import '../../features/interactions/domain/usecases/get_track_likers_usecase.dart';
import '../../features/interactions/domain/usecases/get_track_reposters_usecase.dart';
import '../../features/interactions/presentation/bloc/engagement_list_cubit.dart';
import '../../features/interactions/domain/usecases/get_my_liked_tracks_usecase.dart';
import '../../features/interactions/domain/usecases/get_my_reposted_tracks_usecase.dart';

// Comments
import '../../features/comments/data/datasources/comments_remote_data_source.dart';
import '../../features/comments/data/repositories/comments_repository_impl.dart';
import '../../features/comments/domain/repositories/comments_repository.dart';
import '../../features/comments/domain/usecases/create_comment_usecase.dart';
import '../../features/comments/domain/usecases/delete_comment_usecase.dart';
import '../../features/comments/domain/usecases/get_track_comments_usecase.dart';
import '../../features/comments/domain/usecases/reply_to_comment_usecase.dart';
import '../../features/comments/presentation/bloc/comments_cubit.dart';

import '../network/api_constants.dart';
import '../network/dio_client.dart';
import '../services/audio_player_service.dart';
import '../services/implementations/just_audio_player_service.dart';
import '../storage/secure_storage.dart';

// ── Deep Links / OAuth ─────────────────────────────────────────────────────
import '../../features/playback/data/datasources/track_detail_remote_data_source.dart';
import '../../features/playback/data/repositories/track_detail_repository_impl.dart';
import '../../features/playback/domain/repositories/i_track_detail_repository.dart';
import '../../features/playback/domain/usecases/get_track_detail_use_case.dart';
import '../../features/playback/domain/usecases/get_track_by_secret_use_case.dart';
import '../../features/playback/presentation/bloc/track_loader_cubit.dart';
import '../deep_links/deep_link_service.dart';
import '../oauth/oauth_pending_request_store.dart';
import '../oauth/windows_oauth_callback_server.dart';
//messaging
import '../../features/messaging/data/datasources/messaging_remote_data_source.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/data/datasources/messaging_socket_data_source.dart';
import '../../features/messaging/data/repositories/messaging_realtime_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_realtime_repository.dart';
import '../../features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import '../../features/messaging/domain/usecases/delete_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_conversation_messages_usecase.dart';
import '../../features/messaging/domain/usecases/get_conversations_usecase.dart';
import '../../features/messaging/domain/usecases/get_unread_count_usecase.dart';
import '../../features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import '../../features/messaging/domain/usecases/send_text_message_usecase.dart';
import '../../features/messaging/domain/usecases/share_playlist_message_usecase.dart';
import '../../features/messaging/domain/usecases/share_track_message_usecase.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(
    storage: FileStorage('${appDocDir.path}/.cookies/'),
  );

  if (!getIt.isRegistered<PersistCookieJar>()) {
    getIt.registerLazySingleton<PersistCookieJar>(() => cookieJar);
  }
  // ── Core ─────────────────────────────────────────────────────────────────

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

  if (!getIt.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  }

  if (!getIt.isRegistered<OAuthPendingRequestStore>()) {
    getIt.registerLazySingleton<OAuthPendingRequestStore>(
      () => OAuthPendingRequestStore(getIt<SharedPreferences>()),
    );
  }

  if (!getIt.isRegistered<WindowsOAuthCallbackServer>()) {
    getIt.registerLazySingleton<WindowsOAuthCallbackServer>(
      () => WindowsOAuthCallbackServer(),
    );
  }

  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(
      () => DioClient(
        baseUrl: ApiConstants.baseUrl,
        secureStorage: getIt<SecureStorage>(),
        cookieJar: getIt<PersistCookieJar>(),
      ),
    );
  }

  if (!getIt.isRegistered<SocialRepo>()) {
    getIt.registerLazySingleton<SocialRepo>(
      () => SocialRepo(getIt<DioClient>().dio),
    );
  }

  // ── Core Services ────────────────────────────────────────────────────────

  if (!getIt.isRegistered<DeepLinkService>()) {
    getIt.registerLazySingleton<DeepLinkService>(
      () => DeepLinkService(),
    );
  }

  if (!getIt.isRegistered<TrackDetailRemoteDataSource>()) {
    getIt.registerLazySingleton<TrackDetailRemoteDataSource>(
      () => TrackDetailRemoteDataSource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<ITrackDetailRepository>()) {
    getIt.registerLazySingleton<ITrackDetailRepository>(
      () => TrackDetailRepositoryImpl(getIt<TrackDetailRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTrackDetailUseCase>()) {
    getIt.registerLazySingleton<GetTrackDetailUseCase>(
      () => GetTrackDetailUseCase(getIt<ITrackDetailRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTrackBySecretUseCase>()) {
    getIt.registerLazySingleton<GetTrackBySecretUseCase>(
      () => GetTrackBySecretUseCase(getIt<ITrackDetailRepository>()),
    );
  }

  if (!getIt.isRegistered<AudioPlayerService>()) {
    getIt.registerLazySingleton<AudioPlayerService>(
      () => JustAudioPlayerService(),
    );
  }

  if (!getIt.isRegistered<PlayerCubit>()) {
    getIt.registerLazySingleton<PlayerCubit>(
      () => PlayerCubit(
        getIt<AudioPlayerService>(),
        getTrackDetail: getIt<GetTrackDetailUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<TrackLoaderCubit>()) {
    getIt.registerFactory<TrackLoaderCubit>(
      () => TrackLoaderCubit(
        getTrackDetail: getIt<GetTrackDetailUseCase>(),
        getTrackBySecret: getIt<GetTrackBySecretUseCase>(),
        playerCubit: getIt<PlayerCubit>(),
      ),
    );
  }

  if (!getIt.isRegistered<PlaybackCubit>()) {
    getIt.registerLazySingleton<PlaybackCubit>(
      () => PlaybackCubit(getIt<AudioPlayerService>()),
    );
  }

  // Factory — fresh instance per bridge page, not a singleton
  if (!getIt.isRegistered<TrackLoaderCubit>()) {
    getIt.registerFactory<TrackLoaderCubit>(
      () => TrackLoaderCubit(
        getTrackDetail: getIt<GetTrackDetailUseCase>(),
        getTrackBySecret: getIt<GetTrackBySecretUseCase>(),
        playerCubit: getIt<PlayerCubit>(),
      ),
    );
  }

  // ── Upload Feature: File Picker + Upload Flow ───────────────────────────

  if (!getIt.isRegistered<AudioPickerPermissionService>()) {
    getIt.registerLazySingleton<AudioPickerPermissionService>(
      () => AudioPickerPermissionServiceImpl(),
    );
  }

  if (!getIt.isRegistered<AudioFilePickerDataSource>()) {
    getIt.registerLazySingleton<AudioFilePickerDataSource>(
      () => AudioFilePickerDataSourceImpl(
        getIt<AudioPickerPermissionService>(),
      ),
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
        getIt<WatchTrackProcessingStatusUseCase>(),
        getIt<UpdateTrackVisibilityUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<TrackStatusRemoteDataSource>()) {
    getIt.registerLazySingleton<TrackStatusRemoteDataSource>(
      () => TrackStatusRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<ITrackStatusRepository>()) {
    getIt.registerLazySingleton<ITrackStatusRepository>(
      () => TrackStatusRepositoryImpl(getIt<TrackStatusRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<WatchTrackProcessingStatusUseCase>()) {
    getIt.registerLazySingleton<WatchTrackProcessingStatusUseCase>(
      () => WatchTrackProcessingStatusUseCase(
        getIt<ITrackStatusRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<TrackStatusRemoteDataSource>()) {
    getIt.registerLazySingleton<TrackStatusRemoteDataSource>(
      () => TrackStatusRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<ITrackStatusRepository>()) {
    getIt.registerLazySingleton<ITrackStatusRepository>(
      () => TrackStatusRepositoryImpl(getIt<TrackStatusRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<WatchTrackProcessingStatusUseCase>()) {
    getIt.registerLazySingleton<WatchTrackProcessingStatusUseCase>(
      () => WatchTrackProcessingStatusUseCase(
        getIt<ITrackStatusRepository>(),
      ),
    );
  }

  // ── Upload Feature: Track Management Basics ─────────────────────────────

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

  // ── Auth Feature ─────────────────────────────────────────────────────────

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
        authRepository: getIt<AuthRepository>(),
        windowsOAuthCallbackServer: getIt<WindowsOAuthCallbackServer>(),
        oauthPendingRequestStore: getIt<OAuthPendingRequestStore>(),
      ),
    );
  }

  if (!getIt.isRegistered<RecentlyPlayedCubit>()) {
    if (!getIt.isRegistered<RecentlyPlayedRemoteDataSource>()) {
      getIt.registerLazySingleton<RecentlyPlayedRemoteDataSource>(
        () => RecentlyPlayedRemoteDataSourceImpl(getIt<DioClient>()),
      );
    }

    if (!getIt.isRegistered<RecentlyPlayedRepositoryImpl>()) {
      getIt.registerLazySingleton<RecentlyPlayedRepositoryImpl>(
        () => RecentlyPlayedRepositoryImpl(
            getIt<RecentlyPlayedRemoteDataSource>()),
      );
    }

    if (!getIt.isRegistered<GetRecentlyPlayed>()) {
      getIt.registerLazySingleton<GetRecentlyPlayed>(
        () => GetRecentlyPlayed(getIt<RecentlyPlayedRepositoryImpl>()),
      );
    }

    if (!getIt.isRegistered<RecordRecentlyPlayed>()) {
      getIt.registerLazySingleton<RecordRecentlyPlayed>(
        () => RecordRecentlyPlayed(getIt<RecentlyPlayedRepositoryImpl>()),
      );
    }

    getIt.registerLazySingleton<RecentlyPlayedCubit>(
      () => RecentlyPlayedCubit(
        getRecentlyPlayed: getIt<GetRecentlyPlayed>(),
        recordRecentlyPlayed: getIt<RecordRecentlyPlayed>(),
      ),
    );
  }


  // ── Messaging Feature ────────────────────────────────────────────────────

  if (!getIt.isRegistered<MessagingRemoteDataSource>()) {
    getIt.registerLazySingleton<MessagingRemoteDataSource>(
      () => MessagingRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<MessagingSocketDataSource>()) {
    getIt.registerLazySingleton<MessagingSocketDataSource>(
      () => MessagingSocketDataSourceImpl(
        cookieJar: getIt<PersistCookieJar>(),
      ),
    );
  }

  if (!getIt.isRegistered<MessagingRepository>()) {
    getIt.registerLazySingleton<MessagingRepository>(
      () => MessagingRepositoryImpl(getIt<MessagingRemoteDataSource>()),
    );
  }

if (!getIt.isRegistered<MessagingRealtimeRepository>()) {
  getIt.registerLazySingleton<MessagingRealtimeRepository>(
    () => MessagingRealtimeRepositoryImpl(
      getIt<MessagingSocketDataSource>(),
    ),
  );
}

if (!getIt.isRegistered<ConnectMessagingSocketUseCase>()) {
  getIt.registerLazySingleton<ConnectMessagingSocketUseCase>(
    () => ConnectMessagingSocketUseCase(
      getIt<MessagingRealtimeRepository>(),
    ),
  );
}

  if (!getIt.isRegistered<MessagingRealtimeRepository>()) {
    getIt.registerLazySingleton<MessagingRealtimeRepository>(
      () => MessagingRealtimeRepositoryImpl(
        getIt<MessagingSocketDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetConversationsUseCase>()) {
    getIt.registerLazySingleton<GetConversationsUseCase>(
      () => GetConversationsUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetConversationMessagesUseCase>()) {
    getIt.registerLazySingleton<GetConversationMessagesUseCase>(
      () => GetConversationMessagesUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<SendTextMessageUseCase>()) {
    getIt.registerLazySingleton<SendTextMessageUseCase>(
      () => SendTextMessageUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<ShareTrackMessageUseCase>()) {
    getIt.registerLazySingleton<ShareTrackMessageUseCase>(
      () => ShareTrackMessageUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<SharePlaylistMessageUseCase>()) {
    getIt.registerLazySingleton<SharePlaylistMessageUseCase>(
      () => SharePlaylistMessageUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetUnreadCountUseCase>()) {
    getIt.registerLazySingleton<GetUnreadCountUseCase>(
      () => GetUnreadCountUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkConversationReadUseCase>()) {
    getIt.registerLazySingleton<MarkConversationReadUseCase>(
      () => MarkConversationReadUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteMessageUseCase>()) {
    getIt.registerLazySingleton<DeleteMessageUseCase>(
      () => DeleteMessageUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<ConnectMessagingSocketUseCase>()) {
    getIt.registerLazySingleton<ConnectMessagingSocketUseCase>(
      () => ConnectMessagingSocketUseCase(
        getIt<MessagingRealtimeRepository>(),
      ),
    );
  }

  // ── Profile Feature ──────────────────────────────────────────────────────

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
        getMyLikedTracksUseCase: getIt<GetMyLikedTracksUseCase>(),
        getMyRepostedTracksUseCase: getIt<GetMyRepostedTracksUseCase>(),
      ),
    );
  }

  // ── Interactions Feature ─────────────────────────────────────────────────

  if (!getIt.isRegistered<InteractionsRemoteDataSource>()) {
    getIt.registerLazySingleton<InteractionsRemoteDataSource>(
      () => InteractionsRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<InteractionsRepository>()) {
    getIt.registerLazySingleton<InteractionsRepository>(
      () => InteractionsRepositoryImpl(getIt<InteractionsRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTrackInteractionStatusUseCase>()) {
    getIt.registerLazySingleton<GetTrackInteractionStatusUseCase>(
      () => GetTrackInteractionStatusUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetMyLikedTracksUseCase>()) {
    getIt.registerLazySingleton<GetMyLikedTracksUseCase>(
      () => GetMyLikedTracksUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetMyRepostedTracksUseCase>()) {
    getIt.registerLazySingleton<GetMyRepostedTracksUseCase>(
      () => GetMyRepostedTracksUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<LikeTrackUseCase>()) {
    getIt.registerLazySingleton<LikeTrackUseCase>(
      () => LikeTrackUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<UnlikeTrackUseCase>()) {
    getIt.registerLazySingleton<UnlikeTrackUseCase>(
      () => UnlikeTrackUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<RepostTrackUseCase>()) {
    getIt.registerLazySingleton<RepostTrackUseCase>(
      () => RepostTrackUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<UnrepostTrackUseCase>()) {
    getIt.registerLazySingleton<UnrepostTrackUseCase>(
      () => UnrepostTrackUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTrackLikersUseCase>()) {
    getIt.registerLazySingleton<GetTrackLikersUseCase>(
      () => GetTrackLikersUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTrackRepostersUseCase>()) {
    getIt.registerLazySingleton<GetTrackRepostersUseCase>(
      () => GetTrackRepostersUseCase(getIt<InteractionsRepository>()),
    );
  }

  if (!getIt.isRegistered<TrackInteractionCubit>()) {
    getIt.registerFactory<TrackInteractionCubit>(
      () => TrackInteractionCubit(
        getTrackInteractionStatusUseCase:
            getIt<GetTrackInteractionStatusUseCase>(),
        likeTrackUseCase: getIt<LikeTrackUseCase>(),
        unlikeTrackUseCase: getIt<UnlikeTrackUseCase>(),
        repostTrackUseCase: getIt<RepostTrackUseCase>(),
        unrepostTrackUseCase: getIt<UnrepostTrackUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<EngagementListCubit>()) {
    getIt.registerFactory<EngagementListCubit>(
      () => EngagementListCubit(
        getTrackLikersUseCase: getIt<GetTrackLikersUseCase>(),
        getTrackRepostersUseCase: getIt<GetTrackRepostersUseCase>(),
      ),
    );
  }

  // ── Comments Feature ─────────────────────────────────────────────────────

  if (!getIt.isRegistered<CommentsRemoteDataSource>()) {
    getIt.registerLazySingleton<CommentsRemoteDataSource>(
      () => CommentsRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<CommentsRepository>()) {
    getIt.registerLazySingleton<CommentsRepository>(
      () => CommentsRepositoryImpl(getIt<CommentsRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTrackCommentsUseCase>()) {
    getIt.registerLazySingleton<GetTrackCommentsUseCase>(
      () => GetTrackCommentsUseCase(getIt<CommentsRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateCommentUseCase>()) {
    getIt.registerLazySingleton<CreateCommentUseCase>(
      () => CreateCommentUseCase(getIt<CommentsRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteCommentUseCase>()) {
    getIt.registerLazySingleton<DeleteCommentUseCase>(
      () => DeleteCommentUseCase(getIt<CommentsRepository>()),
    );
  }

  if (!getIt.isRegistered<ReplyToCommentUseCase>()) {
    getIt.registerLazySingleton<ReplyToCommentUseCase>(
      () => ReplyToCommentUseCase(getIt<CommentsRepository>()),
    );
  }

  if (!getIt.isRegistered<CommentsCubit>()) {
    getIt.registerFactory<CommentsCubit>(
      () => CommentsCubit(
        getTrackCommentsUseCase: getIt<GetTrackCommentsUseCase>(),
        createCommentUseCase: getIt<CreateCommentUseCase>(),
        deleteCommentUseCase: getIt<DeleteCommentUseCase>(),
        replyToCommentUseCase: getIt<ReplyToCommentUseCase>(),
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
