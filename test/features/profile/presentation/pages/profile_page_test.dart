import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/profile_page.dart';

import '../../helpers/profile_test_fixtures.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class TestProfileCubit extends ProfileCubit {
  TestProfileCubit({
    required super.getProfileUseCase,
    required super.updateProfileUseCase,
    required super.profileRepository,
  });

  void setTestState(ProfileState state) => emit(state);
}

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockProfileRepository mockProfileRepository;
  late TestProfileCubit profileCubit;

  late ProfileEntity profileWithoutAvatar;
  late ProfileEntity profileWithCover;
  late ProfileEntity profileWithoutBio;
  late ProfileEntity profileWithoutLocation;
  late ProfileEntity profileWithoutGenres;
  late ProfileEntity profileForOwnUser; // Add this

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

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockProfileRepository = MockProfileRepository();

    profileCubit = TestProfileCubit(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
      profileRepository: mockProfileRepository,
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

    // Add profile for own user with matching handle
    profileForOwnUser = ProfileEntity(
      id: tProfileEntity.id,
      displayName: 'Ahmed Hassan',
      handle: 'ahmed-hassan-beats', // Matches ownUser.handle
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
  });

  tearDown(() async {
    await profileCubit.close();
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

      await tester.tap(find.text('Tracks'));
      await tester.pumpAndSettle();

      expect(find.text('No tracks yet'), findsOneWidget);
    });

    testWidgets('own profile tracks tab shows managed tracks', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(ownUser));

      profileCubit.setTestState(ProfileLoaded(profileForOwnUser));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Tap the Tracks tab
      await tester.tap(find.text('Tracks'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // NestedScrollView + TabBarView — scroll to make list items visible
      await tester.drag(
        find.byType(NestedScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Midnight Echoes'), findsOneWidget);
      expect(find.text('City Lights'), findsOneWidget);
      expect(find.text('Manage'), findsNWidgets(2));
    });
  });
}