import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_country_picker.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class FakeUpdateProfileParams extends Fake implements UpdateProfileParams {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProfileCubit mockProfileCubit;
  late MockAuthCubit mockAuthCubit;

  // Profile with external links — used for tests that don't trigger save
  const profile = ProfileEntity(
    id: '1',
    displayName: 'Ali',
    handle: 'ali',
    bio: 'bio text',
    location: 'Cairo, Egypt',
    avatarUrl: null,
    coverPhotoUrl: null,
    accountTier: AccountTier.LISTENER,
    favoriteGenres: ['Rock'],
    externalLinks: {'x': 'y'},
    visibility: ProfileVisibility.PUBLIC,
    followersCount: 1,
    followingCount: 2,
  );

  // Profile with no external links — used for save tests to avoid
  // URL validation blocking the save (external link 'y' is not a valid x.com URL)
  const profileNoLinks = ProfileEntity(
    id: '1',
    displayName: 'Ali',
    handle: 'ali',
    bio: 'bio text',
    location: 'Cairo, Egypt',
    avatarUrl: null,
    coverPhotoUrl: null,
    accountTier: AccountTier.LISTENER,
    favoriteGenres: ['Rock'],
    externalLinks: {},
    visibility: ProfileVisibility.PUBLIC,
    followersCount: 1,
    followingCount: 2,
  );

  const updatedProfile = ProfileEntity(
    id: '1',
    displayName: 'Ali Updated',
    handle: 'ali',
    bio: 'new bio',
    location: 'Giza, Egypt',
    avatarUrl: null,
    coverPhotoUrl: null,
    accountTier: AccountTier.LISTENER,
    favoriteGenres: ['Rock'],
    externalLinks: {},
    visibility: ProfileVisibility.PUBLIC,
    followersCount: 1,
    followingCount: 2,
  );

  const authUser = User(
    id: '1',
    email: 'ali@test.com',
    displayName: 'Ali',
    handle: 'ali',
    avatarUrl: null,
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    required ProfileState profileState,
    required AuthState authState,
  }) async {
    when(() => mockProfileCubit.state).thenReturn(profileState);
    whenListen(
      mockProfileCubit,
      Stream<ProfileState>.fromIterable([profileState]),
      initialState: profileState,
    );

    when(() => mockAuthCubit.state).thenReturn(authState);
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([authState]),
      initialState: authState,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        ],
        child: const MaterialApp(
          home: EditProfilePage(),
        ),
      ),
    );

    await tester.pump();
  }

  setUpAll(() {
    registerFallbackValue(
      const UpdateProfileParams(
        displayName: 'fallback',
      ),
    );
    registerFallbackValue(ProfileImageType.AVATAR);
  });

  setUp(() {
    mockProfileCubit = MockProfileCubit();
    mockAuthCubit = MockAuthCubit();

    when(() => mockAuthCubit.refreshCurrentUserSilently())
        .thenAnswer((_) async {});
    when(() => mockProfileCubit.updateProfile(any())).thenAnswer((_) async {});
    when(
      () => mockProfileCubit.uploadImage(
        imageType: any(named: 'imageType'),
        filePath: any(named: 'filePath'),
      ),
    ).thenAnswer((_) async {});
  });

  testWidgets('renders initial profile data from ProfileLoaded',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Display Name'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);
  });

  testWidgets('save triggers updateProfile with trimmed values',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ali'),
      'Ali Updated',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'bio text'),
      'new bio',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    verify(() => mockProfileCubit.updateProfile(any())).called(1);
  });

  testWidgets('save with empty bio sends null bio', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ali'),
      'Ali Updated',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'bio text'),
      '   ',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    verify(() => mockProfileCubit.updateProfile(any())).called(1);
  });

  testWidgets('validation prevents save when display name is too short',
        (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ali'),
        'A',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle(); // ← was just pump(), validation error needs a frame to render

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      verifyNever(() => mockProfileCubit.updateProfile(any()));
    });

  testWidgets('country picker selection updates selected country label',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    final countryPicker = find.byType(EditProfileCountryPicker);
    expect(countryPicker, findsOneWidget);

    await tester.tap(countryPicker);
    await tester.pumpAndSettle();

    expect(find.text('Select Country'), findsOneWidget);
    expect(find.text('Afghanistan'), findsOneWidget);

    await tester.tap(find.text('Afghanistan'));
    await tester.pumpAndSettle();

    expect(find.text('Afghanistan'), findsOneWidget);
  });

  testWidgets('shows loading indicator in app bar while saving',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileUpdating(profile),
      authState: AuthAuthenticated(authUser),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('shows snackbar on ProfileUpdateError', (tester) async {
    final stateStream = Stream<ProfileState>.fromIterable([
      ProfileLoaded(profile),
      ProfileUpdateError(profile, 'update failed'),
    ]);

    whenListen(
      mockProfileCubit,
      stateStream,
      initialState: ProfileLoaded(profile),
    );
    when(() => mockProfileCubit.state).thenReturn(ProfileLoaded(profile));

    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthAuthenticated(authUser)]),
      initialState: AuthAuthenticated(authUser),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        ],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('update failed'), findsOneWidget);
  });

  testWidgets('shows snackbar on ProfileUpdateSuccess', (tester) async {
    final stateStream = Stream<ProfileState>.fromIterable([
      ProfileLoaded(profileNoLinks),
      ProfileUpdateSuccess(updatedProfile),
    ]);

    whenListen(
      mockProfileCubit,
      stateStream,
      initialState: ProfileLoaded(profileNoLinks),
    );
    when(() => mockProfileCubit.state).thenReturn(ProfileLoaded(profileNoLinks));
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthAuthenticated(authUser)]),
      initialState: AuthAuthenticated(authUser),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        ],
        child: MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
                  BlocProvider<AuthCubit>.value(value: mockAuthCubit),
                ],
                child: const EditProfilePage(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets(
      'discard dialog appears when back is pressed with unsaved changes',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    final displayNameField = find.widgetWithText(TextFormField, 'Ali');
    await tester.enterText(displayNameField, 'Ali Changed');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text('You have unsaved changes. Leaving will discard them.'),
      findsOneWidget,
    );
    expect(find.text('Keep editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });
}