import 'package:flutter/widgets.dart';
import '../config/app_config.dart';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/data/datasources/recently_played_remote_datasource.dart';
import 'package:soundcloud_clone/features/recently_played/data/repositories/recently_played_repository_impl.dart';
import 'package:soundcloud_clone/features/recently_played/domain/usecases/get_recently_played.dart';

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

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/data/repositories/queue_repository.dart';

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
import '../../features/feed/data/datasources/feed_remote_data_sources.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/get_feed.dart';
import '../../features/feed/domain/usecases/toggle_like.dart';
import '../../features/feed/domain/usecases/toggle_repost.dart';
import '../../features/feed/presentation/bloc/feed_cubit.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_content_usecase.dart';
import '../../features/home/domain/usecases/get_home_trending_tracks_usecase.dart';
import '../../features/home/presentation/bloc/home_cubit.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart'
    as profile_data;
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as profile_repo;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as profile_domain;
import '../../features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';

import '../../features/social/data/repositories/social_repo.dart';

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

// Playlists
import '../../features/playlists/data/datasources/playlists_remote_data_source.dart';
import '../../features/playlists/data/repositories/playlists_repository_impl.dart';
import '../../features/playlists/domain/repositories/playlists_repository.dart';
import '../../features/playlists/domain/usecases/add_track_to_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/create_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/delete_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/get_my_playlists_usecase.dart';
import '../../features/playlists/domain/usecases/get_playlist_details_usecase.dart';
import '../../features/playlists/domain/usecases/get_playlist_edit_details_usecase.dart';
import '../../features/playlists/domain/usecases/get_playlist_embed_code_usecase.dart';
import '../../features/playlists/domain/usecases/get_recent_playlists_usecase.dart';
import '../../features/playlists/domain/usecases/get_liked_playlists_usecase.dart';
import '../../features/playlists/domain/usecases/get_top_playlists_usecase.dart';
import '../../features/playlists/domain/usecases/like_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/remove_track_from_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/reorder_playlist_tracks_usecase.dart';
import '../../features/playlists/domain/usecases/record_playlist_playback_usecase.dart';
import '../../features/playlists/domain/usecases/resolve_secret_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/unlike_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/update_playlist_usecase.dart';
import '../../features/playlists/domain/usecases/upload_playlist_cover_usecase.dart';
import '../../features/playlists/presentation/bloc/playlists_cubit.dart';
import '../../features/library/presentation/bloc/library_cubit.dart';
import '../../features/comments/data/datasources/comments_remote_data_source.dart';
import '../../features/comments/data/repositories/comments_repository_impl.dart';
import '../../features/comments/domain/repositories/comments_repository.dart';
import '../../features/comments/domain/usecases/create_comment_usecase.dart';
import '../../features/comments/domain/usecases/delete_comment_usecase.dart';
import '../../features/comments/domain/usecases/get_track_comments_usecase.dart';
import '../../features/comments/domain/usecases/reply_to_comment_usecase.dart';
import '../../features/comments/presentation/bloc/comments_cubit.dart';
import '../../features/notifications/notifications_injection.dart';
import '../../features/notifications/data/services/fcm_registration_service.dart';
import '../../features/notifications/data/services/notifications_realtime_refresh_service.dart';

import '../../features/search/data/datasources/search_remote_data_source.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/search_usecase.dart';
import '../../features/search/presentation/bloc/search_cubit.dart';

import '../network/api_constants.dart';
import '../network/dio_client.dart';
import '../services/audio_player_service.dart';
import '../services/implementations/just_audio_player_service.dart';
import '../storage/secure_storage.dart';

import '../../features/playback/data/datasources/track_detail_remote_data_source.dart';
import '../../features/playback/data/repositories/track_detail_repository_impl.dart';
import '../../features/playback/domain/repositories/i_track_detail_repository.dart';
import '../../features/playback/domain/usecases/get_track_detail_use_case.dart';
import '../../features/playback/domain/usecases/get_track_by_secret_use_case.dart';
import '../../features/playback/presentation/bloc/track_loader_cubit.dart';
import '../deep_links/deep_link_service.dart';
import '../oauth/oauth_pending_request_store.dart';
import '../oauth/windows_oauth_callback_server.dart';

// Messaging
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
import '../../features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import '../../features/messaging/domain/usecases/get_unread_count_usecase.dart';
import '../../features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import '../../features/messaging/domain/usecases/send_text_message_usecase.dart';
import '../../features/messaging/domain/usecases/share_playlist_message_usecase.dart';
import '../../features/messaging/domain/usecases/share_track_message_usecase.dart';
import '../../features/messaging/presentation/bloc/unread_count_cubit.dart';
import '../../features/messaging/presentation/bloc/share_track_to_conversation_cubit.dart';
import '../../features/messaging/presentation/bloc/start_direct_conversation_cubit.dart';
import '../../features/messaging/domain/usecases/archive_conversation_usecase.dart';
import '../../features/messaging/domain/usecases/get_conversation_meta_usecase.dart';
import '../../features/messaging/domain/usecases/mark_conversation_unread_usecase.dart';
import '../../features/messaging/domain/usecases/unarchive_conversation_usecase.dart';

import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/check_upload_limit_usecase.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/subscription_repository_impl.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/premium/premium_di.dart';
import '../../features/discovery/data/datasources/discovery_remote_data_source.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/data/repositories/trending_repository_impl.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/discovery/domain/repositories/trending_repository.dart';
import '../../features/discovery/domain/usecases/get_trending_usecase.dart';
import '../../features/discovery/domain/usecases/resolve_resource_usecase.dart';
import '../../features/discovery/presentation/bloc/discovery_cubit.dart';
import '../../features/discovery/presentation/bloc/trending_cubit.dart';

import '../../features/search/data/datasources/genre_remote_datasource.dart';
import '../../features/search/data/repositories/genre_repository_impl.dart';
import '../../features/search/domain/repositories/genre_repository.dart';
import '../../features/search/domain/usecases/genre_usecase.dart';
import '../../features/search/presentation/bloc/genre_cubit.dart';

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
  registerPremiumDependencies(getIt);

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

  // ── Queue Repository — لازم يتسجل قبل PlayerCubit و PlaybackCubit ────────

  if (!getIt.isRegistered<QueueRepository>()) {
    getIt.registerLazySingleton<QueueRepository>(
      () => QueueRepository(getIt<DioClient>()),
    );
  }

  // ── PlayerCubit ──────────────────────────────────────────────────────────

  if (!getIt.isRegistered<PlayerCubit>()) {
    getIt.registerLazySingleton<PlayerCubit>(
      () => PlayerCubit(
        getIt<AudioPlayerService>(),
        getTrackDetail: getIt<GetTrackDetailUseCase>(),
        queueRepository: getIt<QueueRepository>(), // ✅
      ),
    );
  }

  // ── PlaybackCubit ────────────────────────────────────────────────────────

  if (!getIt.isRegistered<PlaybackCubit>()) {
    getIt.registerLazySingleton<PlaybackCubit>(
      () => PlaybackCubit(
        getIt<AudioPlayerService>(),
        getIt<QueueRepository>(), // ✅
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

  if (!getIt.isRegistered<UploadPickerCubit>()) {
    getIt.registerFactory<UploadPickerCubit>(
      () => UploadPickerCubit(
        getIt<PickAudioFileUseCase>(),
        getIt<UploadRepository>(),
        getIt<WatchTrackProcessingStatusUseCase>(),
        getIt<UpdateTrackVisibilityUseCase>(),
        getIt<SubscriptionRepository>(),
        getIt<CheckUploadLimitUseCase>(),
      ),
    );
  }

  // ── Upload Feature: Track Management ────────────────────────────────────

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
          ? TrackManagementRepositoryFake(mode: mockTrackManagementMode)
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

  // ── Notifications Feature ───────────────────────────────────────────────
  registerNotificationsModule(getIt);

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
        fcmRegistrationService: getIt<FcmRegistrationService>(),
      ),
    );
  }

  // ── Recently Played Feature ──────────────────────────────────────────────

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
        secureStorage: getIt<SecureStorage>(),
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

  if (!getIt.isRegistered<GetConversationsUseCase>()) {
    getIt.registerLazySingleton<GetConversationsUseCase>(
      () => GetConversationsUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<GetOrCreateDirectConversationUseCase>()) {
    getIt.registerLazySingleton<GetOrCreateDirectConversationUseCase>(
      () => GetOrCreateDirectConversationUseCase(getIt<MessagingRepository>()),
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
      () => ConnectMessagingSocketUseCase(getIt<MessagingRealtimeRepository>()),
    );
  }

  if (!getIt.isRegistered<NotificationsRealtimeRefreshService>()) {
    getIt.registerLazySingleton<NotificationsRealtimeRefreshService>(
      () => NotificationsRealtimeRefreshService(
        getIt<ConnectMessagingSocketUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<UnreadCountCubit>()) {
    getIt.registerFactory<UnreadCountCubit>(
      () => UnreadCountCubit(
        getUnreadCountUseCase: getIt<GetUnreadCountUseCase>(),
        connectMessagingSocketUseCase: getIt<ConnectMessagingSocketUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<ShareTrackToConversationCubit>()) {
    getIt.registerFactory<ShareTrackToConversationCubit>(
      () => ShareTrackToConversationCubit(
        getConversationsUseCase: getIt<GetConversationsUseCase>(),
        shareTrackMessageUseCase: getIt<ShareTrackMessageUseCase>(),
        sharePlaylistMessageUseCase: getIt<SharePlaylistMessageUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<StartDirectConversationCubit>()) {
    getIt.registerFactory<StartDirectConversationCubit>(
      () => StartDirectConversationCubit(
        getOrCreateDirectConversationUseCase:
            getIt<GetOrCreateDirectConversationUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetConversationMetaUseCase>()) {
    getIt.registerLazySingleton<GetConversationMetaUseCase>(
      () => GetConversationMetaUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkConversationUnreadUseCase>()) {
    getIt.registerLazySingleton<MarkConversationUnreadUseCase>(
      () => MarkConversationUnreadUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<ArchiveConversationUseCase>()) {
    getIt.registerLazySingleton<ArchiveConversationUseCase>(
      () => ArchiveConversationUseCase(getIt<MessagingRepository>()),
    );
  }

  if (!getIt.isRegistered<UnarchiveConversationUseCase>()) {
    getIt.registerLazySingleton<UnarchiveConversationUseCase>(
      () => UnarchiveConversationUseCase(getIt<MessagingRepository>()),
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

  // ── Search Feature ───────────────────────────────────────────────────────

  if (!getIt.isRegistered<SearchRemoteDataSource>()) {
    getIt.registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<SearchRepository>()) {
    getIt.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(getIt<SearchRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<SearchUseCase>()) {
    getIt.registerLazySingleton<SearchUseCase>(
      () => SearchUseCase(getIt<SearchRepository>()),
    );
  }

  if (!getIt.isRegistered<SearchCubit>()) {
    getIt.registerFactory<SearchCubit>(
      () => SearchCubit(getIt<SearchUseCase>()),
    );
  }

  // ── Feed Feature ─────────────────────────────────────────────────────────

  if (!getIt.isRegistered<FeedRemoteDataSource>()) {
    getIt.registerLazySingleton<FeedRemoteDataSource>(
      () => FeedRemoteDataSourceImpl(client: getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<FeedRepository>()) {
    getIt.registerLazySingleton<FeedRepository>(
      () => FeedRepositoryImpl(
        dataSource: getIt<FeedRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetFeedUseCase>()) {
    getIt.registerLazySingleton<GetFeedUseCase>(
      () => GetFeedUseCase(getIt<FeedRepository>()),
    );
  }

  if (!getIt.isRegistered<ToggleLikeUseCase>()) {
    getIt.registerLazySingleton<ToggleLikeUseCase>(
      () => ToggleLikeUseCase(getIt<FeedRepository>()),
    );
  }

  if (!getIt.isRegistered<ToggleRepostUseCase>()) {
    getIt.registerLazySingleton<ToggleRepostUseCase>(
      () => ToggleRepostUseCase(getIt<FeedRepository>()),
    );
  }

  if (!getIt.isRegistered<FeedCubit>()) {
    getIt.registerFactory<FeedCubit>(
      () => FeedCubit(
        getFeed: getIt<GetFeedUseCase>(),
        toggleLike: getIt<ToggleLikeUseCase>(),
        toggleRepost: getIt<ToggleRepostUseCase>(),
        repository: getIt<FeedRepository>(),
      ),
    );
  }
  // ── Discovery Feature ────────────────────────────────────────────────────

  if (!getIt.isRegistered<DiscoveryRemoteDataSource>()) {
    getIt.registerLazySingleton<DiscoveryRemoteDataSource>(
      () => DiscoveryRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<DiscoveryRepository>()) {
    getIt.registerLazySingleton<DiscoveryRepository>(
      () => DiscoveryRepositoryImpl(getIt<DiscoveryRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<ResolveResourceUseCase>()) {
    getIt.registerLazySingleton<ResolveResourceUseCase>(
      () => ResolveResourceUseCase(getIt<DiscoveryRepository>()),
    );
  }

  if (!getIt.isRegistered<DiscoveryCubit>()) {
    getIt.registerFactory<DiscoveryCubit>(
      () => DiscoveryCubit(getIt<ResolveResourceUseCase>()),
    );
  }

  if (!getIt.isRegistered<TrendingRepository>()) {
    getIt.registerLazySingleton<TrendingRepository>(
      () => TrendingRepositoryImpl(
        remoteDataSource: getIt<DiscoveryRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetTrendingUseCase>()) {
    getIt.registerLazySingleton<GetTrendingUseCase>(
      () => GetTrendingUseCase(getIt<TrendingRepository>()),
    );
  }

  if (!getIt.isRegistered<TrendingCubit>()) {
    getIt.registerFactory<TrendingCubit>(
      () => TrendingCubit(
        getTrendingUseCase: getIt<GetTrendingUseCase>(),
      ),
    );
  }

  // ── Genre Discovery Feature ──────────────────────────────────────────────

  if (!getIt.isRegistered<GenreRemoteDatasource>()) {
    getIt.registerLazySingleton<GenreRemoteDatasource>(
      () => GenreRemoteDatasource(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<GenreRepository>()) {
    getIt.registerLazySingleton<GenreRepository>(
      () => GenreRepositoryImpl(getIt<GenreRemoteDatasource>()),
    );
  }

  if (!getIt.isRegistered<GenreUseCase>()) {
    getIt.registerLazySingleton<GenreUseCase>(
      () => GenreUseCase(getIt<GenreRepository>()),
    );
  }

  if (!getIt.isRegistered<FollowUserUseCase>()) {
    getIt.registerLazySingleton<FollowUserUseCase>(
      () => FollowUserUseCase(getIt<GenreRepository>()),
    );
  }

  if (!getIt.isRegistered<GenreCubit>()) {
    getIt.registerFactory<GenreCubit>(
      () => GenreCubit(
        getIt<GenreUseCase>(),
        getIt<FollowUserUseCase>(),
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

  // ── Playlists Feature ───────────────────────────────────────────────────

  if (!getIt.isRegistered<PlaylistsRemoteDataSource>()) {
    getIt.registerLazySingleton<PlaylistsRemoteDataSource>(
      () => PlaylistsRemoteDataSourceImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<PlaylistsRepository>()) {
    getIt.registerLazySingleton<PlaylistsRepository>(
      () => PlaylistsRepositoryImpl(getIt<PlaylistsRemoteDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetMyPlaylistsUseCase>()) {
    getIt.registerLazySingleton<GetMyPlaylistsUseCase>(
      () => GetMyPlaylistsUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<CreatePlaylistUseCase>()) {
    getIt.registerLazySingleton<CreatePlaylistUseCase>(
      () => CreatePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetPlaylistDetailsUseCase>()) {
    getIt.registerLazySingleton<GetPlaylistDetailsUseCase>(
      () => GetPlaylistDetailsUseCase(getIt<PlaylistsRepository>()),
    );
  }
  if (!getIt.isRegistered<GetPlaylistEditDetailsUseCase>()) {
    getIt.registerLazySingleton<GetPlaylistEditDetailsUseCase>(
      () => GetPlaylistEditDetailsUseCase(getIt<PlaylistsRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdatePlaylistUseCase>()) {
    getIt.registerLazySingleton<UpdatePlaylistUseCase>(
      () => UpdatePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }
  if (!getIt.isRegistered<UploadPlaylistCoverUseCase>()) {
    getIt.registerLazySingleton<UploadPlaylistCoverUseCase>(
      () => UploadPlaylistCoverUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetRecentPlaylistsUseCase>()) {
    getIt.registerLazySingleton<GetRecentPlaylistsUseCase>(
      () => GetRecentPlaylistsUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetLikedPlaylistsUseCase>()) {
    getIt.registerLazySingleton<GetLikedPlaylistsUseCase>(
      () => GetLikedPlaylistsUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetTopPlaylistsUseCase>()) {
    getIt.registerLazySingleton<GetTopPlaylistsUseCase>(
      () => GetTopPlaylistsUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<LikePlaylistUseCase>()) {
    getIt.registerLazySingleton<LikePlaylistUseCase>(
      () => LikePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<UnlikePlaylistUseCase>()) {
    getIt.registerLazySingleton<UnlikePlaylistUseCase>(
      () => UnlikePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<RecordPlaylistPlaybackUseCase>()) {
    getIt.registerLazySingleton<RecordPlaylistPlaybackUseCase>(
      () => RecordPlaylistPlaybackUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<DeletePlaylistUseCase>()) {
    getIt.registerLazySingleton<DeletePlaylistUseCase>(
      () => DeletePlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<AddTrackToPlaylistUseCase>()) {
    getIt.registerLazySingleton<AddTrackToPlaylistUseCase>(
      () => AddTrackToPlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<RemoveTrackFromPlaylistUseCase>()) {
    getIt.registerLazySingleton<RemoveTrackFromPlaylistUseCase>(
      () => RemoveTrackFromPlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<ReorderPlaylistTracksUseCase>()) {
    getIt.registerLazySingleton<ReorderPlaylistTracksUseCase>(
      () => ReorderPlaylistTracksUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<ResolveSecretPlaylistUseCase>()) {
    getIt.registerLazySingleton<ResolveSecretPlaylistUseCase>(
      () => ResolveSecretPlaylistUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<GetPlaylistEmbedCodeUseCase>()) {
    getIt.registerLazySingleton<GetPlaylistEmbedCodeUseCase>(
      () => GetPlaylistEmbedCodeUseCase(getIt<PlaylistsRepository>()),
    );
  }

  if (!getIt.isRegistered<PlaylistsCubit>()) {
    getIt.registerFactory<PlaylistsCubit>(
      () => PlaylistsCubit(
        getMyPlaylistsUseCase: getIt<GetMyPlaylistsUseCase>(),
        createPlaylistUseCase: getIt<CreatePlaylistUseCase>(),
        getPlaylistDetailsUseCase: getIt<GetPlaylistDetailsUseCase>(),
        getPlaylistEditDetailsUseCase: getIt<GetPlaylistEditDetailsUseCase>(),
        updatePlaylistUseCase: getIt<UpdatePlaylistUseCase>(),
        uploadPlaylistCoverUseCase: getIt<UploadPlaylistCoverUseCase>(),
        deletePlaylistUseCase: getIt<DeletePlaylistUseCase>(),
        addTrackToPlaylistUseCase: getIt<AddTrackToPlaylistUseCase>(),
        removeTrackFromPlaylistUseCase: getIt<RemoveTrackFromPlaylistUseCase>(),
        reorderPlaylistTracksUseCase: getIt<ReorderPlaylistTracksUseCase>(),
        resolveSecretPlaylistUseCase: getIt<ResolveSecretPlaylistUseCase>(),
        getPlaylistEmbedCodeUseCase: getIt<GetPlaylistEmbedCodeUseCase>(),
        likePlaylistUseCase: getIt<LikePlaylistUseCase>(),
        unlikePlaylistUseCase: getIt<UnlikePlaylistUseCase>(),
        recordPlaylistPlaybackUseCase: getIt<RecordPlaylistPlaybackUseCase>(),
      ),
    );
  }

  // ── Home Feature ────────────────────────────────────────────────────────

  if (!getIt.isRegistered<HomeRepository>()) {
    getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        profileRepository: getIt<profile_domain.ProfileRepository>(),
        playlistsRepository: getIt<PlaylistsRepository>(),
        discoveryRemoteDataSource: getIt<DiscoveryRemoteDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetHomeContentUseCase>()) {
    getIt.registerLazySingleton<GetHomeContentUseCase>(
      () => GetHomeContentUseCase(getIt<HomeRepository>()),
    );
  }

  if (!getIt.isRegistered<GetHomeTrendingTracksUseCase>()) {
    getIt.registerLazySingleton<GetHomeTrendingTracksUseCase>(
      () => GetHomeTrendingTracksUseCase(getIt<HomeRepository>()),
    );
  }

  if (!getIt.isRegistered<HomeCubit>()) {
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        getHomeContent: getIt<GetHomeContentUseCase>(),
        getHomeTrendingTracks: getIt<GetHomeTrendingTracksUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<LibraryCubit>()) {
    getIt.registerFactory<LibraryCubit>(
      () => LibraryCubit(
        getRecentPlaylistsUseCase: getIt<GetRecentPlaylistsUseCase>(),
        getLikedPlaylistsUseCase: getIt<GetLikedPlaylistsUseCase>(),
      ),
    );
  }

  // ── Premium Feature ─────────────────────────────────────────────────────

  if (!getIt.isRegistered<SubscriptionRepository>()) {
    getIt.registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<CheckUploadLimitUseCase>()) {
    getIt.registerLazySingleton<CheckUploadLimitUseCase>(
      () => CheckUploadLimitUseCase(),
    );
  }

  if (!getIt.isRegistered<SubscriptionCubit>()) {
    getIt.registerLazySingleton<SubscriptionCubit>(
      () => SubscriptionCubit(getIt<SubscriptionRepository>()),
    );
  }

  // ── Offline Feature ─────────────────────────────────────────────────────

  if (!getIt.isRegistered<OfflineRepository>()) {
    getIt.registerLazySingleton<OfflineRepository>(
      () => OfflineRepository(getIt<DioClient>()),
    );
  }

  if (!getIt.isRegistered<OfflineCubit>()) {
    getIt.registerLazySingleton<OfflineCubit>(
      () => OfflineCubit(getIt<OfflineRepository>()),
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
