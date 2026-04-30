import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_my_liked_tracks_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_my_reposted_tracks_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/start_direct_conversation_cubit.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/profile_page.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

import '../../helpers/profile_test_fixtures.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockGetMyLikedTracksUseCase extends Mock
    implements GetMyLikedTracksUseCase {}

class MockGetMyRepostedTracksUseCase extends Mock
    implements GetMyRepostedTracksUseCase {}

class MockGetOrCreateDirectConversationUseCase extends Mock
    implements GetOrCreateDirectConversationUseCase {}

class TestProfileCubit extends ProfileCubit {
  TestProfileCubit({
    required super.getProfileUseCase,
    required super.updateProfileUseCase,
    required super.profileRepository,
    required super.getMyLikedTracksUseCase,
    required super.getMyRepostedTracksUseCase,
  });

  void setTestState(ProfileState state) => emit(state);
}

void main() {
  final getIt = GetIt.I;

  late MockAuthCubit mockAuthCubit;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockProfileRepository mockProfileRepository;
  late MockGetMyLikedTracksUseCase mockGetMyLikedTracksUseCase;
  late MockGetMyRepostedTracksUseCase mockGetMyRepostedTracksUseCase;
  late MockGetOrCreateDirectConversationUseCase
      mockGetOrCreateDirectConversationUseCase;
  late TestProfileCubit profileCubit;

  late ProfileEntity profileWithoutAvatar;
  late ProfileEntity profileWithCover;
  late ProfileEntity profileWithoutBio;
  late ProfileEntity profileWithoutLocation;
  late ProfileEntity profileWithoutGenres;
  late ProfileEntity profileForOwnUser;

  const ownUser = User(
    id: '1',
    email: 'ahmed@example.com',
    handle: 'ahmed-hassan-beats',
    displayName: 'Ahmed',
    avatarUrl: null,
  );

  const otherUser = User(
    id: '2',
    email: 'other@example.com',
    handle: 'other-user',
    displayName: 'Other',
    avatarUrl: null,
  );

  setUp(() async {
    await getIt.reset();

    mockAuthCubit = MockAuthCubit();
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockProfileRepository = MockProfileRepository();
    mockGetMyLikedTracksUseCase = MockGetMyLikedTracksUseCase();
    mockGetMyRepostedTracksUseCase = MockGetMyRepostedTracksUseCase();
    mockGetOrCreateDirectConversationUseCase =
        MockGetOrCreateDirectConversationUseCase();

    profileCubit = TestProfileCubit(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
      profileRepository: mockProfileRepository,
      getMyLikedTracksUseCase: mockGetMyLikedTracksUseCase,
      getMyRepostedTracksUseCase: mockGetMyRepostedTracksUseCase,
    );

    getIt.registerFactory<StartDirectConversationCubit>(
      () => StartDirectConversationCubit(
        getOrCreateDirectConversationUseCase:
            mockGetOrCreateDirectConversationUseCase,
      ),
    );

    when(
      () => mockGetOrCreateDirectConversationUseCase(
        receiverId: any(named: 'receiverId'),
      ),
    ).thenAnswer(
      (_) async => const ConversationEntity(
        conversationId: 'conversation-1',
        participant: ParticipantEntity(
          id: 'receiver-1',
          displayName: 'Test User',
          handle: 'testuser',
          avatarUrl: null,
        ),
        lastMessage: null,
        unreadCount: 0,
      ),
    );

    profileWithoutAvatar = ProfileEntity(
      id: tProfileEntity.id,
      displayName: tProfileEntity.displayName,
      handle: tProfileEntity.handle,
      bio: tProfileEntity.bio,
      location: tProfileEntity.location,
      avatarUrl: null,
      coverPhotoUrl: null,
      accountTier: tProfileEntity.accountTier,
      favoriteGenres: tProfileEntity.favoriteGenres,
      externalLinks: tProfileEntity.externalLinks,
      visibility: tProfileEntity.visibility,
      followersCount: tProfileEntity.followersCount,
      followingCount: tProfileEntity.followingCount,
    );

    profileForOwnUser = ProfileEntity(
      id: tProfileEntity.id,
      displayName: 'Ahmed Hassan',
      handle: 'ahmed-hassan-beats',
      bio: 'Music producer',
      location: 'Cairo, Egypt',
      avatarUrl: null,
      coverPhotoUrl: null,
      accountTier: tProfileEntity.accountTier,
      favoriteGenres: tProfileEntity.favoriteGenres,
      externalLinks: tProfileEntity.externalLinks,
      visibility: tProfileEntity.visibility,
      followersCount: tProfileEntity.followersCount,
      followingCount: tProfileEntity.followingCount,
    );

    profileWithCover = ProfileEntity(
      id: tProfileEntity.id,
      displayName: tProfileEntity.displayName,
      handle: tProfileEntity.handle,
      bio: tProfileEntity.bio,
      location: tProfileEntity.location,
      avatarUrl: null,
      coverPhotoUrl: 'http://127.0.0.1:3006/uploads/cover.png',
      accountTier: tProfileEntity.accountTier,
      favoriteGenres: tProfileEntity.favoriteGenres,
      externalLinks: tProfileEntity.externalLinks,
      visibility: tProfileEntity.visibility,
      followersCount: tProfileEntity.followersCount,
      followingCount: tProfileEntity.followingCount,
    );

    profileWithoutBio = ProfileEntity(
      id: tProfileEntity.id,
      displayName: tProfileEntity.displayName,
      handle: tProfileEntity.handle,
      bio: null,
      location: tProfileEntity.location,
      avatarUrl: null,
      coverPhotoUrl: null,
      accountTier: tProfileEntity.accountTier,
      favoriteGenres: tProfileEntity.favoriteGenres,
      externalLinks: tProfileEntity.externalLinks,
      visibility: tProfileEntity.visibility,
      followersCount: tProfileEntity.followersCount,
      followingCount: tProfileEntity.followingCount,
    );

    profileWithoutLocation = ProfileEntity(
      id: tProfileEntity.id,
      displayName: tProfileEntity.displayName,
      handle: tProfileEntity.handle,
      bio: tProfileEntity.bio,
      location: null,
      avatarUrl: null,
      coverPhotoUrl: null,
      accountTier: tProfileEntity.accountTier,
      favoriteGenres: tProfileEntity.favoriteGenres,
      externalLinks: tProfileEntity.externalLinks,
      visibility: tProfileEntity.visibility,
      followersCount: tProfileEntity.followersCount,
      followingCount: tProfileEntity.followingCount,
    );

    profileWithoutGenres = ProfileEntity(
      id: tProfileEntity.id,
      displayName: tProfileEntity.displayName,
      handle: tProfileEntity.handle,
      bio: tProfileEntity.bio,
      location: tProfileEntity.location,
      avatarUrl: null,
      coverPhotoUrl: null,
      accountTier: tProfileEntity.accountTier,
      favoriteGenres: const [],
      externalLinks: tProfileEntity.externalLinks,
      visibility: tProfileEntity.visibility,
      followersCount: tProfileEntity.followersCount,
      followingCount: tProfileEntity.followingCount,
    );

    when(() => mockAuthCubit.emailChangeCooldownRemainingSeconds).thenReturn(0);
    when(
      () => mockAuthCubit.requestEmailChange(
        newEmail: any(named: 'newEmail'),
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockAuthCubit.refreshCurrentUserSilently())
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await profileCubit.close();
    await getIt.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: ProfilePage(
          handle: 'ahmed-hassan-beats',
          cubit: profileCubit,
        ),
      ),
    );
  }

  group('ProfilePage', () {
    testWidgets('shows loading state', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with message', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileError('Failed to load profile'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
    });

    testWidgets('renders loaded own profile basic info', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text(profileWithoutAvatar.displayName), findsOneWidget);
      expect(find.text(profileWithoutAvatar.bio!), findsOneWidget);
      expect(find.text(profileWithoutAvatar.location!), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Tracks'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Reposts'), findsOneWidget);
    });

    testWidgets('renders follow button for non-own profile', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(otherUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('toggles follow button text when tapped', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(otherUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Follow'));
      await tester.pump();

      expect(find.text('Following'), findsOneWidget);

      await tester.tap(find.text('Following'));
      await tester.pump();

      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('shows cover image section when coverPhotoUrl exists',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoaded(profileWithCover));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('does not render bio text when bio is null', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutBio));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      if (tProfileEntity.bio != null) {
        expect(find.text(tProfileEntity.bio!), findsNothing);
      }
    });

    testWidgets('does not render location row when location is null',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutLocation));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      if (tProfileEntity.location != null) {
        expect(find.text(tProfileEntity.location!), findsNothing);
      }
    });

    testWidgets('does not render favorite genres when genres are empty',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutGenres));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      for (final genre in tProfileEntity.favoriteGenres) {
        expect(find.text(genre), findsNothing);
      }
    });

    testWidgets('shows non-own-profile UI when auth state is unauthenticated',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthUnauthenticated());

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('tracks tab shows no tracks text for non-own profile',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(otherUser));

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final tracksTab = find.widgetWithText(Tab, 'Tracks');
      await tester.ensureVisible(tracksTab);
      await tester.pumpAndSettle();
      await tester.tap(tracksTab);
      await tester.pumpAndSettle();

      expect(find.text('No tracks yet'), findsOneWidget);
    });

    testWidgets('own profile tracks tab shows managed tracks', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(
        ProfileLoaded(
          profileForOwnUser,
          tracks: const [
            ManagedTrack(
              id: 'profile-track-1',
              title: 'Midnight Echoes',
              description: 'Layered synth pads',
              tags: <String>['ambient', 'night'],
              visibility: TrackManagementVisibility.publicTrack,
            ),
            ManagedTrack(
              id: 'profile-track-2',
              title: 'City Lights',
              description: 'Private draft',
              tags: <String>['draft'],
              visibility: TrackManagementVisibility.privateTrack,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final tracksTab = find.widgetWithText(Tab, 'Tracks');
      await tester.ensureVisible(tracksTab);
      await tester.pumpAndSettle();
      await tester.tap(tracksTab);
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(NestedScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Midnight Echoes'), findsOneWidget);
      expect(find.text('City Lights'), findsOneWidget);
      expect(find.text('Manage'), findsNWidgets(2));
      expect(find.text('Layered synth pads'), findsOneWidget);
      expect(find.text('#ambient · #night'), findsOneWidget);
    });
  });

  group('Profile state switching coverage', () {
    final statesToTest = <ProfileState>[
      ProfileUpdating(tProfileEntity),
      ProfileUpdateSuccess(tProfileEntity),
      ProfileUpdateError(tProfileEntity, 'Error'),
      ProfileImageUploading(tProfileEntity, ProfileImageType.AVATAR),
    ];

    for (final state in statesToTest) {
      testWidgets('renders body correctly for state: ${state.runtimeType}',
          (tester) async {
        when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
        profileCubit.setTestState(state);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.byType(NestedScrollView), findsOneWidget);
      });
    }
  });

  group('External links and auth listener coverage', () {
    testWidgets('shows snackbar for invalid non-http external link',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      profileCubit.setTestState(
        ProfileLoaded(
          tProfileEntity.copyWith(
            externalLinks: const {'x': 'mailto:user@example.com'},
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.alternate_email));
      await tester.pump();

      expect(find.text('Invalid link'), findsOneWidget);
    });

    testWidgets('long press external link does not crash', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      profileCubit.setTestState(
        ProfileLoaded(
          tProfileEntity.copyWith(
            externalLinks: const {'website': 'https://example.com'},
          ),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.longPress(find.byTooltip('Website\nhttps://example.com'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('shows snackbar on AuthEmailChangeRequested', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      whenListen(
        mockAuthCubit,
        Stream<AuthState>.fromIterable([
          AuthAuthenticated(ownUser),
          AuthEmailChangeRequested(user: ownUser, newEmail: 'new@test.com'),
        ]),
        initialState: AuthAuthenticated(ownUser),
      );

      profileCubit.setTestState(ProfileLoaded(tProfileEntity));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('new@test.com'), findsOneWidget);
    });

    testWidgets('shows snackbar on AuthEmailChangeConfirmed', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      whenListen(
        mockAuthCubit,
        Stream<AuthState>.fromIterable([
          AuthAuthenticated(ownUser),
          AuthEmailChangeConfirmed(),
        ]),
        initialState: AuthAuthenticated(ownUser),
      );

      profileCubit.setTestState(ProfileLoaded(tProfileEntity));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Email updated successfully'), findsOneWidget);
    });

    testWidgets('change email dialog validates empty fields', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      profileCubit.setTestState(ProfileLoaded(tProfileEntity));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('change Email'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send link'));
      await tester.pump();

      expect(find.text('Please enter a new email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('renders private chip and website text when present',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      final privateProfile = profileForOwnUser.copyWith(
        visibility: ProfileVisibility.PRIVATE,
        website: 'https://example.com',
      );

      profileCubit.setTestState(ProfileLoaded(privateProfile));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Private'), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
    });

    testWidgets('own profile tracks tab shows empty state when no tracks',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit
          .setTestState(ProfileLoaded(profileForOwnUser, tracks: const []));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final tracksTab = find.widgetWithText(Tab, 'Tracks');
      await tester.ensureVisible(tracksTab);
      await tester.pumpAndSettle();
      await tester.tap(tracksTab);
      await tester.pumpAndSettle();

      expect(find.text('No tracks yet.'), findsOneWidget);
    });

    testWidgets('renders body correctly for ProfileImageUploadError state',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(
        ProfileImageUploadError(
          profileForOwnUser,
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/avatar.png',
          message: 'upload failed',
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(NestedScrollView), findsOneWidget);
      expect(find.text(profileForOwnUser.displayName), findsOneWidget);
    });

    testWidgets('change email dialog validates invalid email format',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      profileCubit.setTestState(ProfileLoaded(tProfileEntity));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('change Email'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New email'),
        'bad-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'password123',
      );

      await tester.tap(find.text('Send link'));
      await tester.pump();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
    });

    testWidgets('change email dialog shows cooldown message', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));
      when(() => mockAuthCubit.emailChangeCooldownRemainingSeconds)
          .thenReturn(30);

      profileCubit.setTestState(ProfileLoaded(tProfileEntity));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('change Email'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'password123',
      );

      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Wait 30 seconds before resending.'),
        findsOneWidget,
      );
      verifyNever(
        () => mockAuthCubit.requestEmailChange(
          newEmail: any(named: 'newEmail'),
          currentPassword: any(named: 'currentPassword'),
        ),
      );
    });

    testWidgets('change email dialog shows failure returned from auth cubit',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthEmailChangeFailure(
          user: ownUser,
          message: 'Invalid password',
        ),
      );

      when(
        () => mockAuthCubit.requestEmailChange(
          newEmail: any(named: 'newEmail'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async {});

      profileCubit.setTestState(ProfileLoaded(tProfileEntity));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('change Email'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'wrong-password',
      );

      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid password'), findsOneWidget);
    });
  });
}
