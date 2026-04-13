import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soundcloud_clone/main.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/services/implementations/just_audio_player_service.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_service.dart';

import 'package:soundcloud_clone/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:soundcloud_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/confirm_email_change_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/is_logged_in_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/login_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/logout_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/register_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/request_email_change_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

import 'package:soundcloud_clone/features/playback/data/datasources/track_detail_remote_data_source.dart';
import 'package:soundcloud_clone/features/playback/domain/repositories/i_track_detail_repository.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_by_secret_use_case.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_cubit.dart';

import 'package:soundcloud_clone/features/upload/data/datasources/audio_file_picker_data_source.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_management_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/track_status_remote_data_source.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/i_track_status_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/track_management_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/upload_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/delete_track_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pick_audi_file_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_metadata_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_visibility_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/watch_track_processing_status_use_case.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';
import 'package:soundcloud_clone/features/upload/data/services/audio_picker_permission_service.dart';

import 'package:soundcloud_clone/features/profile/data/datasources/profile_remote_data_source.dart'
    as profile_data;
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart'
    as profile_domain;
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';

import 'package:soundcloud_clone/features/interactions/data/datasources/interactions_remote_data_source.dart';
import 'package:soundcloud_clone/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_track_interaction_status_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/like_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/repost_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/unlike_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/unrepost_track_usecase.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';

import 'package:soundcloud_clone/features/comments/data/datasources/comments_remote_data_source.dart';
import 'package:soundcloud_clone/features/comments/domain/repositories/comments_repository.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/create_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/delete_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/get_track_comments_usecase.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/reply_to_comment_usecase.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';

import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

class FakeAudioHandler extends BaseAudioHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    audioHandler = FakeAudioHandler();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await getIt.reset();

    getIt.registerLazySingleton<AudioPlayerService>(
      () => JustAudioPlayerService(handler: audioHandler),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Basic pre-registration
  // ══════════════════════════════════════════════════════════════════════════

  group('Pre-registered singletons', () {
    test('AudioPlayerService is registered', () {
      final service = getIt<AudioPlayerService>();
      expect(service, isNotNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Full setupDependencies
  // ══════════════════════════════════════════════════════════════════════════

  group('setupDependencies — all registrations', () {
    setUp(() async {
      await setupDependencies();
    });

    // ── Core ────────────────────────────────────────────────────────────────
    test('registers DioClient', () {
      expect(getIt.isRegistered<DioClient>(), isTrue);
      expect(getIt<DioClient>(), isNotNull);
    });

    test('registers SecureStorage', () {
      expect(getIt.isRegistered<SecureStorage>(), isTrue);
    });

    test('registers DeepLinkService', () {
      expect(getIt.isRegistered<DeepLinkService>(), isTrue);
      expect(getIt<DeepLinkService>(), isNotNull);
    });

    test('registers SocialRepo', () {
      expect(getIt.isRegistered<SocialRepo>(), isTrue);
    });

    // ── Playback ────────────────────────────────────────────────────────────
    test('registers TrackDetailRemoteDataSource', () {
      expect(getIt.isRegistered<TrackDetailRemoteDataSource>(), isTrue);
    });

    test('registers ITrackDetailRepository', () {
      expect(getIt.isRegistered<ITrackDetailRepository>(), isTrue);
    });

    test('registers GetTrackDetailUseCase', () {
      expect(getIt.isRegistered<GetTrackDetailUseCase>(), isTrue);
    });

    test('registers GetTrackBySecretUseCase', () {
      expect(getIt.isRegistered<GetTrackBySecretUseCase>(), isTrue);
    });

    test('registers PlayerCubit', () {
      expect(getIt.isRegistered<PlayerCubit>(), isTrue);
      expect(getIt<PlayerCubit>(), isNotNull);
    });

    test('registers PlaybackCubit', () {
      expect(getIt.isRegistered<PlaybackCubit>(), isTrue);
    });

    test('registers TrackLoaderCubit as factory (fresh each time)', () {
      expect(getIt.isRegistered<TrackLoaderCubit>(), isTrue);
      final a = getIt<TrackLoaderCubit>();
      final b = getIt<TrackLoaderCubit>();
      expect(identical(a, b), isFalse);
    });

    // ── Upload ──────────────────────────────────────────────────────────────
    test('registers AudioPickerPermissionService', () {
      expect(getIt.isRegistered<AudioPickerPermissionService>(), isTrue);
    });

    test('registers AudioFilePickerDataSource', () {
      expect(getIt.isRegistered<AudioFilePickerDataSource>(), isTrue);
    });

    test('registers UploadRepository', () {
      expect(getIt.isRegistered<UploadRepository>(), isTrue);
    });

    test('registers PickAudioFileUseCase', () {
      expect(getIt.isRegistered<PickAudioFileUseCase>(), isTrue);
    });

    test('registers UploadPickerCubit as factory', () {
      expect(getIt.isRegistered<UploadPickerCubit>(), isTrue);
      final a = getIt<UploadPickerCubit>();
      final b = getIt<UploadPickerCubit>();
      expect(identical(a, b), isFalse);
    });

    test('registers TrackStatusRemoteDataSource', () {
      expect(getIt.isRegistered<TrackStatusRemoteDataSource>(), isTrue);
    });

    test('registers ITrackStatusRepository', () {
      expect(getIt.isRegistered<ITrackStatusRepository>(), isTrue);
    });

    test('registers WatchTrackProcessingStatusUseCase', () {
      expect(getIt.isRegistered<WatchTrackProcessingStatusUseCase>(), isTrue);
    });

    test('registers TrackManagementRemoteDataSource', () {
      expect(getIt.isRegistered<TrackManagementRemoteDataSource>(), isTrue);
    });

    test('registers TrackManagementRepository', () {
      expect(getIt.isRegistered<TrackManagementRepository>(), isTrue);
    });

    test('registers UpdateTrackMetadataUseCase', () {
      expect(getIt.isRegistered<UpdateTrackMetadataUseCase>(), isTrue);
    });

    test('registers UpdateTrackVisibilityUseCase', () {
      expect(getIt.isRegistered<UpdateTrackVisibilityUseCase>(), isTrue);
    });

    test('registers DeleteTrackUseCase', () {
      expect(getIt.isRegistered<DeleteTrackUseCase>(), isTrue);
    });

    test('registers TrackManagementCubit as factory', () {
      expect(getIt.isRegistered<TrackManagementCubit>(), isTrue);
      final a = getIt<TrackManagementCubit>();
      final b = getIt<TrackManagementCubit>();
      expect(identical(a, b), isFalse);
    });

    // ── Auth ─────────────────────────────────────────────────────────────────
    test('registers AuthRemoteDataSource', () {
      expect(getIt.isRegistered<AuthRemoteDataSource>(), isTrue);
    });

    test('registers AuthLocalDataSource', () {
      expect(getIt.isRegistered<AuthLocalDataSource>(), isTrue);
    });

    test('registers AuthRepository', () {
      expect(getIt.isRegistered<AuthRepository>(), isTrue);
    });

    test('registers LoginUseCase', () {
      expect(getIt.isRegistered<LoginUseCase>(), isTrue);
    });

    test('registers RegisterUseCase', () {
      expect(getIt.isRegistered<RegisterUseCase>(), isTrue);
    });

    test('registers LogoutUseCase', () {
      expect(getIt.isRegistered<LogoutUseCase>(), isTrue);
    });

    test('registers IsLoggedInUseCase', () {
      expect(getIt.isRegistered<IsLoggedInUseCase>(), isTrue);
    });

    test('registers GetCurrentUserUseCase', () {
      expect(getIt.isRegistered<GetCurrentUserUseCase>(), isTrue);
    });

    test('registers ForgotPasswordUseCase', () {
      expect(getIt.isRegistered<ForgotPasswordUseCase>(), isTrue);
    });

    test('registers ResetPasswordUseCase', () {
      expect(getIt.isRegistered<ResetPasswordUseCase>(), isTrue);
    });

    test('registers SendEmailVerificationUseCase', () {
      expect(getIt.isRegistered<SendEmailVerificationUseCase>(), isTrue);
    });

    test('registers VerifyEmailUseCase', () {
      expect(getIt.isRegistered<VerifyEmailUseCase>(), isTrue);
    });

    test('registers RequestEmailChangeUseCase', () {
      expect(getIt.isRegistered<RequestEmailChangeUseCase>(), isTrue);
    });

    test('registers ConfirmEmailChangeUseCase', () {
      expect(getIt.isRegistered<ConfirmEmailChangeUseCase>(), isTrue);
    });

    test('registers AuthCubit as factory', () {
      expect(getIt.isRegistered<AuthCubit>(), isTrue);
      final a = getIt<AuthCubit>();
      final b = getIt<AuthCubit>();
      expect(identical(a, b), isFalse);
    });

    test('registers RecentlyPlayedCubit', () {
      expect(getIt.isRegistered<RecentlyPlayedCubit>(), isTrue);
    });

    // ── Profile ──────────────────────────────────────────────────────────────
    test('registers ProfileRemoteDataSource', () {
      expect(
          getIt.isRegistered<profile_data.ProfileRemoteDataSource>(), isTrue);
    });

    test('registers ProfileRepository', () {
      expect(getIt.isRegistered<profile_domain.ProfileRepository>(), isTrue);
    });

    test('registers GetProfileUseCase', () {
      expect(getIt.isRegistered<GetProfileUseCase>(), isTrue);
    });

    test('registers UpdateProfileUseCase', () {
      expect(getIt.isRegistered<UpdateProfileUseCase>(), isTrue);
    });

    test('registers ProfileCubit as factory', () {
      expect(getIt.isRegistered<ProfileCubit>(), isTrue);
      final a = getIt<ProfileCubit>();
      final b = getIt<ProfileCubit>();
      expect(identical(a, b), isFalse);
    });

    // ── Interactions ─────────────────────────────────────────────────────────
    test('registers InteractionsRemoteDataSource', () {
      expect(getIt.isRegistered<InteractionsRemoteDataSource>(), isTrue);
    });

    test('registers InteractionsRepository', () {
      expect(getIt.isRegistered<InteractionsRepository>(), isTrue);
    });

    test('registers GetTrackInteractionStatusUseCase', () {
      expect(getIt.isRegistered<GetTrackInteractionStatusUseCase>(), isTrue);
    });

    test('registers LikeTrackUseCase', () {
      expect(getIt.isRegistered<LikeTrackUseCase>(), isTrue);
    });

    test('registers UnlikeTrackUseCase', () {
      expect(getIt.isRegistered<UnlikeTrackUseCase>(), isTrue);
    });

    test('registers RepostTrackUseCase', () {
      expect(getIt.isRegistered<RepostTrackUseCase>(), isTrue);
    });

    test('registers UnrepostTrackUseCase', () {
      expect(getIt.isRegistered<UnrepostTrackUseCase>(), isTrue);
    });

    test('registers TrackInteractionCubit as factory', () {
      expect(getIt.isRegistered<TrackInteractionCubit>(), isTrue);
      final a = getIt<TrackInteractionCubit>();
      final b = getIt<TrackInteractionCubit>();
      expect(identical(a, b), isFalse);
    });

    // ── Comments ─────────────────────────────────────────────────────────────
    test('registers CommentsRemoteDataSource', () {
      expect(getIt.isRegistered<CommentsRemoteDataSource>(), isTrue);
    });

    test('registers CommentsRepository', () {
      expect(getIt.isRegistered<CommentsRepository>(), isTrue);
    });

    test('registers GetTrackCommentsUseCase', () {
      expect(getIt.isRegistered<GetTrackCommentsUseCase>(), isTrue);
    });

    test('registers CreateCommentUseCase', () {
      expect(getIt.isRegistered<CreateCommentUseCase>(), isTrue);
    });

    test('registers DeleteCommentUseCase', () {
      expect(getIt.isRegistered<DeleteCommentUseCase>(), isTrue);
    });

    test('registers ReplyToCommentUseCase', () {
      expect(getIt.isRegistered<ReplyToCommentUseCase>(), isTrue);
    });

    test('registers CommentsCubit as factory', () {
      expect(getIt.isRegistered<CommentsCubit>(), isTrue);
      final a = getIt<CommentsCubit>();
      final b = getIt<CommentsCubit>();
      expect(identical(a, b), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Idempotency — calling setupDependencies twice should not throw
  // ══════════════════════════════════════════════════════════════════════════

  group('setupDependencies idempotency', () {
    test('can be called twice without throwing', () async {
      await setupDependencies();
      await Future<void>.delayed(Duration.zero);
      await setupDependencies();
      await Future<void>.delayed(Duration.zero);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // _parseMockTrackManagementMode (tested indirectly via AppConfig)
  // The function is private but exercised through setupDependencies which
  // reads AppConfig.mockTrackManagementMode.  We just confirm no exception.
  // ══════════════════════════════════════════════════════════════════════════

  group('Mock track management mode parsing', () {
    test('setupDependencies completes without error (default mode)', () async {
      await setupDependencies();
      await Future<void>.delayed(Duration.zero);
    });
  });
}
