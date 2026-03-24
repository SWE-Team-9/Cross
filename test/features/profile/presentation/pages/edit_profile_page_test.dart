import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/edit_profile_page.dart';

import '../../helpers/profile_test_fixtures.dart';

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
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockProfileRepository mockProfileRepository;
  late TestProfileCubit cubit;
  late ProfileEntity profileWithoutImages;

  setUpAll(() {
    registerFallbackValue(
      const UpdateProfileParams(displayName: 'fallback'),
    );
  });

  setUp(() {
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockProfileRepository = MockProfileRepository();

    cubit = TestProfileCubit(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
      profileRepository: mockProfileRepository,
    );

    profileWithoutImages = ProfileEntity(
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

    cubit.setTestState(ProfileLoaded(profileWithoutImages));
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<ProfileCubit>.value(
        value: cubit,
        child: const EditProfilePage(),
      ),
    );
  }

  group('EditProfilePage', () {
    testWidgets('renders initial profile values', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
      expect(find.text('Bio'), findsOneWidget);

      expect(find.text(profileWithoutImages.displayName), findsOneWidget);
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text('Egypt'), findsAtLeastNWidgets(1));
      expect(find.text(profileWithoutImages.bio!), findsOneWidget);
    });

    testWidgets('shows validation error when display name is too short',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final displayNameField = find.byType(TextFormField).first;
      await tester.enterText(displayNameField, 'A');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      verifyNever(() => mockUpdateProfileUseCase(any()));
    });

    testWidgets('calls updateProfile with trimmed form values', (tester) async {
      when(() => mockUpdateProfileUseCase(any()))
          .thenAnswer((_) async => profileWithoutImages);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));

      await tester.enterText(fields.at(0), '  Ali Mahmoud  ');
      await tester.enterText(fields.at(1), '  Giza  ');
      await tester.enterText(fields.at(2), '  Updated bio  ');

      await tester.tap(find.text('Save'));
      await tester.pump();

      final captured = verify(() => mockUpdateProfileUseCase(captureAny()))
          .captured
          .single as UpdateProfileParams;

      expect(captured.displayName, 'Ali Mahmoud');
      expect(captured.bio, 'Updated bio');
      expect(captured.location, 'Giza, Egypt');
    });

    testWidgets('passes null bio when bio field is blank', (tester) async {
      when(() => mockUpdateProfileUseCase(any()))
          .thenAnswer((_) async => profileWithoutImages);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), 'Ali Mahmoud');
      await tester.enterText(fields.at(1), 'Cairo');
      await tester.enterText(fields.at(2), '');

      await tester.tap(find.text('Save'));
      await tester.pump();

      final captured = verify(() => mockUpdateProfileUseCase(captureAny()))
          .captured
          .single as UpdateProfileParams;

      expect(captured.displayName, 'Ali Mahmoud');
      expect(captured.bio, isNull);
      expect(captured.location, 'Cairo, Egypt');
    });

    testWidgets('shows snackbar on ProfileUpdateError state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      cubit.setTestState(
        ProfileUpdateError(profileWithoutImages, 'Update failed'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Update failed'), findsOneWidget);
    });

    testWidgets('shows progress indicator in app bar while saving',
        (tester) async {
      cubit.setTestState(ProfileUpdating(profileWithoutImages));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets(
        'opens discard dialog when back is pressed with unsaved changes',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final displayNameField = find.byType(TextFormField).first;
      await tester.enterText(displayNameField, 'Changed Name');
      await tester.pump();

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

    testWidgets('closes discard dialog when Keep editing is tapped',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final displayNameField = find.byType(TextFormField).first;
      await tester.enterText(displayNameField, 'Changed Name');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.byType(EditProfilePage), findsOneWidget);
    });
  });
}
