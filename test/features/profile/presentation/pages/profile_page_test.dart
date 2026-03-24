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
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ahmed@example.com',
            handle: 'ahmed-hassan-beats',
            displayName: 'Ahmed',
            avatarUrl: null,
          ),
        ),
      );

      profileCubit.setTestState(ProfileLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with message', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ahmed@example.com',
            handle: 'ahmed-hassan-beats',
            displayName: 'Ahmed',
            avatarUrl: null,
          ),
        ),
      );

      profileCubit.setTestState(ProfileError('Failed to load profile'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
    });

    testWidgets('renders loaded own profile basic info', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ahmed@example.com',
            handle: 'ahmed-hassan-beats',
            displayName: 'Ahmed',
            avatarUrl: null,
          ),
        ),
      );

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
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'other@example.com',
            handle: 'other-user',
            displayName: 'Other',
            avatarUrl: null,
          ),
        ),
      );

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('toggles follow button text when tapped', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'other@example.com',
            handle: 'other-user',
            displayName: 'Other',
            avatarUrl: null,
          ),
        ),
      );

      profileCubit.setTestState(ProfileLoaded(profileWithoutAvatar));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Follow'));
      await tester.pump();

      expect(find.text('Following'), findsOneWidget);
    });
  });
}
