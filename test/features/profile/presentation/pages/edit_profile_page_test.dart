import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_country_picker.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_text_field.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class FakeUpdateProfileParams extends Fake implements UpdateProfileParams {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProfileCubit mockProfileCubit;
  late MockAuthCubit mockAuthCubit;

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
    bool settle = true,
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

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  setUpAll(() {
    registerFallbackValue(
      const UpdateProfileParams(displayName: 'fallback'),
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

  Finder findFieldByLabel(String label) {
    return find.descendant(
      of: find.widgetWithText(EditProfileTextField, label),
      matching: find.byType(TextFormField),
    );
  }

  Future<void> addExternalLink(
    WidgetTester tester, {
    required String platformLabel,
    required String url,
  }) async {
    await tester.dragUntilVisible(
      find.text('Add link'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text(platformLabel).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, url);
    await tester.pumpAndSettle();
  }

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
    expect(find.text('Country'), findsWidgets);
    expect(find.text('Bio'), findsOneWidget);
  });

  testWidgets('save triggers updateProfile with trimmed values',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    expect(find.text('Ali'), findsWidgets);

    final displayNameField = findFieldByLabel('Display Name');
    await tester.enterText(displayNameField, 'Ali Updated');
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(TextButton, 'Save');
    expect(saveButton, findsOneWidget);

    await tester.tap(saveButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    verify(() => mockProfileCubit.updateProfile(any())).called(1);
  });

  testWidgets('avatar change is staged and uploaded only after save',
      (tester) async {
    when(() => mockProfileCubit.state)
        .thenReturn(ProfileLoaded(profileNoLinks));
    whenListen(
      mockProfileCubit,
      Stream<ProfileState>.fromIterable([ProfileLoaded(profileNoLinks)]),
      initialState: ProfileLoaded(profileNoLinks),
    );

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
          home: EditProfilePage(
            pickAndCropImageOverride: (_) async => '/tmp/new-avatar.png',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    var saveButton =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    saveButton =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    final savedButtonState =
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
    expect(savedButtonState.onPressed, isNull);

    verify(
      () => mockProfileCubit.uploadImage(
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/new-avatar.png',
      ),
    ).called(1);
    verify(() => mockAuthCubit.refreshCurrentUserSilently()).called(1);
    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('validation prevents save when display name is too short',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    final displayNameField = findFieldByLabel('Display Name');
    await tester.enterText(displayNameField, 'A');
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(TextButton, 'Save');
    await tester.tap(saveButton);
    await tester.pump(const Duration(milliseconds: 300));

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
    await tester.tap(countryPicker);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Afghanistan'));
    await tester.pumpAndSettle();

    expect(find.text('Afghanistan'), findsOneWidget);
  });

  testWidgets('shows snackbar on ProfileUpdateError', (tester) async {
    final stateStream = Stream<ProfileState>.fromIterable([
      ProfileLoaded(profile),
      ProfileUpdateError(profile, 'Failed to update profile'),
    ]);

    whenListen(
      mockProfileCubit,
      stateStream,
      initialState: ProfileLoaded(profile),
    );

    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(EditProfilePage), findsOneWidget);
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

    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('duplicate external platform shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.text('Add link'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).last,
      'https://x.com/user',
    );

    await tester.dragUntilVisible(
      find.text('Add link'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('invalid website URL shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    final websiteField = findFieldByLabel('Website');
    await tester.enterText(websiteField, 'invalid-url');

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 500));

    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('invalid instagram link shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.text('Add link'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).last,
      'https://instagram.com/p/post',
    );

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Instagram'), findsOneWidget);
  });

  testWidgets('remove external link confirms deletion', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.byIcon(Icons.delete_outline).first,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('No external links added yet.'), findsOneWidget);
  });

  testWidgets('clear all external links works', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.text('Clear all'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfilePage), findsOneWidget);
  });

  testWidgets('account type switch updates UI text', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.byType(DropdownButtonFormField<AccountTier>),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    final dropdown = find.byType(DropdownButtonFormField<AccountTier>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Artist').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Artists can access'), findsOneWidget);
  });

  testWidgets('privacy toggle updates text', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.byType(Switch),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    final toggle = find.byType(Switch);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.textContaining('private'), findsOneWidget);
  });

  testWidgets('discard dialog appears when back is pressed', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    final displayNameField = findFieldByLabel('Display Name');
    await tester.enterText(displayNameField, 'Changed');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
  });

  group('External Link Validation', () {
    testWidgets('fails when adding the same platform twice', (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      await tester.dragUntilVisible(
        find.text('Add link'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );

      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();

      final firstCount = find.byType(TextFormField).evaluate().length;
      await tester.enterText(
        find.byType(TextFormField).at(firstCount - 1),
        'https://instagram.com/user1',
      );

      await tester.dragUntilVisible(
        find.text('Add link'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );

      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();

      final secondCount = find.byType(TextFormField).evaluate().length;
      await tester.enterText(
        find.byType(TextFormField).at(secondCount - 1),
        'https://instagram.com/user2',
      );

      await tester.dragUntilVisible(
        find.text('Save'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verifyNever(() => mockProfileCubit.updateProfile(any()));
    });

    testWidgets('validates Instagram profile-only constraint', (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      await tester.dragUntilVisible(
        find.text('Add link'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );

      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();

      final count = find.byType(TextFormField).evaluate().length;
      await tester.enterText(
        find.byType(TextFormField).at(count - 1),
        'https://instagram.com/reels/xyz',
      );

      await tester.dragUntilVisible(
        find.text('Save'),
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verifyNever(() => mockProfileCubit.updateProfile(any()));
    });

    testWidgets('normalizes URLs missing https protocol', (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      final websiteField = findFieldByLabel('Website');
      await tester.enterText(websiteField, 'facebook.com/user');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockProfileCubit.updateProfile(captureAny()))
              .captured
              .single as UpdateProfileParams;

      expect(captured.website, 'https://facebook.com/user');
    });
  });

  group('Image Section', () {
    testWidgets('renders image pick affordances', (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });
  });

  group('Unsaved Changes Guard', () {
    testWidgets('does not show discard dialog when no changes were made',
        (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('stays on page if Keep editing is pressed', (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      final displayNameField = findFieldByLabel('Display Name');
      await tester.enterText(displayNameField, 'Changed Name');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(EditProfilePage), findsOneWidget);
    });
  });

  group('State Synchronization', () {
    testWidgets('updates form fields when profile state carries updated values',
        (tester) async {
      const updatedFromState = ProfileEntity(
        id: '1',
        displayName: 'Ali Synced',
        handle: 'ali',
        bio: 'bio text',
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

      when(() => mockProfileCubit.state)
          .thenReturn(ProfileLoaded(profileNoLinks));
      whenListen(
        mockProfileCubit,
        Stream<ProfileState>.fromIterable([
          ProfileLoaded(profileNoLinks),
          ProfileUpdateError(updatedFromState, 'sync'),
        ]),
        initialState: ProfileLoaded(profileNoLinks),
      );

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
      await tester.pumpAndSettle();

      final displayNameField = findFieldByLabel('Display Name');
      final textFormField = tester.widget<TextFormField>(displayNameField);
      expect(textFormField.controller?.text, 'Ali Synced');
    });

    testWidgets('parses location correctly into City and Country fields',
        (tester) async {
      await pumpPage(
        tester,
        profileState: ProfileLoaded(profileNoLinks),
        authState: AuthAuthenticated(authUser),
      );

      final cityField = findFieldByLabel('City');
      final cityTextField = tester.widget<TextFormField>(cityField);

      expect(cityTextField.controller?.text, 'Cairo');
      expect(find.text('Egypt'), findsWidgets);
    });
  });

  testWidgets('save does nothing when there are no unsaved changes',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('shows retry snackbar for avatar image upload error',
      (tester) async {
    final controller = StreamController<ProfileState>();

    when(() => mockProfileCubit.state)
        .thenReturn(ProfileLoaded(profileNoLinks));
    whenListen(
      mockProfileCubit,
      controller.stream,
      initialState: ProfileLoaded(profileNoLinks),
    );

    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthAuthenticated(authUser)]),
      initialState: AuthAuthenticated(authUser),
    );

    when(
      () => mockProfileCubit.uploadImage(
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/avatar.png',
      ),
    ).thenAnswer((_) async {});

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

    await tester.pumpAndSettle();

    controller.add(
      ProfileImageUploadError(
        profileNoLinks,
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/avatar.png',
        message: 'Image upload failed',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Image upload failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(
      () => mockProfileCubit.uploadImage(
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/avatar.png',
      ),
    ).called(1);

    await controller.close();
  });

  testWidgets('hides image upload error snackbar when upload retry starts',
      (tester) async {
    final controller = StreamController<ProfileState>();

    when(() => mockProfileCubit.state)
        .thenReturn(ProfileLoaded(profileNoLinks));
    whenListen(
      mockProfileCubit,
      controller.stream,
      initialState: ProfileLoaded(profileNoLinks),
    );

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
        child: const MaterialApp(
          home: EditProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.add(
      ProfileImageUploadError(
        profileNoLinks,
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/avatar.png',
        message: 'Image upload failed',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Image upload failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    controller.add(
      ProfileImageUploading(
        profileNoLinks,
        ProfileImageType.AVATAR,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Image upload failed'), findsNothing);
    expect(find.text('Retry'), findsNothing);

    await controller.close();
  });

  testWidgets('shows avatar upload loading state', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileImageUploading(
        profileNoLinks,
        ProfileImageType.AVATAR,
      ),
      authState: AuthAuthenticated(authUser),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows cover upload loading state', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileImageUploading(
        profileNoLinks,
        ProfileImageType.COVER,
      ),
      authState: AuthAuthenticated(authUser),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('keeps page rendered on image upload error state',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileImageUploadError(
        profileNoLinks,
        imageType: ProfileImageType.COVER,
        filePath: '/tmp/cover.png',
        message: 'Upload failed',
      ),
      authState: AuthAuthenticated(authUser),
    );

    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('invalid facebook link shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await addExternalLink(
      tester,
      platformLabel: 'Facebook',
      url: 'https://facebook.com/watch/video',
    );

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Facebook link must point to a profile'),
      findsOneWidget,
    );
    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('invalid youtube link shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await addExternalLink(
      tester,
      platformLabel: 'YouTube',
      url: 'https://youtube.com/watch?v=123',
    );

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('YouTube link must point to a channel/profile'),
      findsOneWidget,
    );
    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('invalid tiktok link shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await addExternalLink(
      tester,
      platformLabel: 'TikTok',
      url: 'https://tiktok.com/discover',
    );

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('TikTok link must point to a profile'),
      findsOneWidget,
    );
    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('invalid x link shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await addExternalLink(
      tester,
      platformLabel: 'X',
      url: 'https://x.com/home',
    );

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('X link must point to a profile'),
      findsOneWidget,
    );
    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('invalid soundcloud link shows error', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profileNoLinks),
      authState: AuthAuthenticated(authUser),
    );

    await addExternalLink(
      tester,
      platformLabel: 'SoundCloud',
      url: 'https://soundcloud.com/discover',
    );

    await tester.dragUntilVisible(
      find.text('Save'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('SoundCloud link must point to a profile'),
      findsOneWidget,
    );
    verifyNever(() => mockProfileCubit.updateProfile(any()));
  });

  testWidgets('cancel remove external link keeps the item', (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.byIcon(Icons.delete_outline).first,
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(find.text('No external links added yet.'), findsNothing);
  });

  testWidgets('cancel clear all external links keeps the items',
      (tester) async {
    await pumpPage(
      tester,
      profileState: ProfileLoaded(profile),
      authState: AuthAuthenticated(authUser),
    );

    await tester.dragUntilVisible(
      find.text('Clear all'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(find.text('No external links added yet.'), findsNothing);
  });

  testWidgets('shows retry snackbar for cover image upload error',
      (tester) async {
    final controller = StreamController<ProfileState>();

    when(() => mockProfileCubit.state)
        .thenReturn(ProfileLoaded(profileNoLinks));
    whenListen(
      mockProfileCubit,
      controller.stream,
      initialState: ProfileLoaded(profileNoLinks),
    );

    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthAuthenticated(authUser)]),
      initialState: AuthAuthenticated(authUser),
    );

    when(
      () => mockProfileCubit.uploadImage(
        imageType: ProfileImageType.COVER,
        filePath: '/tmp/cover.png',
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileCubit>.value(value: mockProfileCubit),
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        ],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );

    await tester.pumpAndSettle();

    controller.add(
      ProfileImageUploadError(
        profileNoLinks,
        imageType: ProfileImageType.COVER,
        filePath: '/tmp/cover.png',
        message: 'Cover upload failed',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cover upload failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(
      () => mockProfileCubit.uploadImage(
        imageType: ProfileImageType.COVER,
        filePath: '/tmp/cover.png',
      ),
    ).called(1);

    await controller.close();
  });

  testWidgets('refreshes auth user after profile update success',
      (tester) async {
    final stateStream = Stream<ProfileState>.fromIterable([
      ProfileLoaded(profileNoLinks),
      ProfileUpdateSuccess(updatedProfile),
    ]);

    when(() => mockProfileCubit.state)
        .thenReturn(ProfileLoaded(profileNoLinks));
    whenListen(
      mockProfileCubit,
      stateStream,
      initialState: ProfileLoaded(profileNoLinks),
    );

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
        child: const MaterialApp(
          home: EditProfilePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    verify(() => mockAuthCubit.refreshCurrentUserSilently()).called(1);
  });
}
