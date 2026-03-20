import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/profile/data/repositories/profileRepositoryFake.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/uploadProfileImageUseCase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadCubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profileImageUploadState.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/ProfileImageUploadDemoPage.dart';

class TestProfileImageUploadCubit extends ProfileImageUploadCubit {
  TestProfileImageUploadCubit(super.uploadProfileImageUseCase);

  void seed(ProfileImageUploadState state) {
    emit(state);
  }
}

Uint8List _validPngBytes() {
  return Uint8List.fromList(<int>[
    137, 80, 78, 71, 13, 10, 26, 10,
    0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1,
    8, 6, 0, 0, 0, 31, 21, 196,
    137, 0, 0, 0, 13, 73, 68, 65,
    84, 120, 156, 99, 248, 255, 255, 63,
    0, 5, 254, 2, 254, 167, 53, 129,
    132, 0, 0, 0, 0, 73, 69, 78,
    68, 174, 66, 96, 130,
  ]);
}

void main() {
  final GetIt getIt = GetIt.instance;

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders initial demo page state', (tester) async {
    getIt.registerFactory<ProfileImageUploadCubit>(
      () => ProfileImageUploadCubit(
        UploadProfileImageUseCase(
          ProfileRepositoryFake(
            mode: MockProfileImageUploadMode.success,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileImageUploadDemoPage(),
      ),
    );

    expect(find.text('Profile Image Upload Demo'), findsOneWidget);
    expect(find.text('Cover'), findsOneWidget);
    expect(find.text('Avatar'), findsOneWidget);
    expect(find.text('Change Cover'), findsOneWidget);
    expect(find.text('Change Avatar'), findsOneWidget);
  });

  testWidgets('renders prepared image section when image is ready',
      (tester) async {
    final Uint8List imageBytes = _validPngBytes();

    final cubit = TestProfileImageUploadCubit(
      UploadProfileImageUseCase(
        ProfileRepositoryFake(
          mode: MockProfileImageUploadMode.success,
        ),
      ),
    );

    cubit.seed(
      ProfileImageUploadState(
        status: ProfileImageUploadStatus.ready,
        activeImageType: ProfileImageType.avatar,
        previewBytes: imageBytes,
        selectedFileName: 'avatar.jpg',
        selectedMimeType: 'image/jpeg',
        selectedFileSizeInBytes: imageBytes.lengthInBytes,
        currentCoverBytes: imageBytes,
      ),
    );

    getIt.registerFactory<ProfileImageUploadCubit>(() => cubit);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileImageUploadDemoPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Prepared image'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('File name'), findsOneWidget);
    expect(find.text('MIME type'), findsOneWidget);
    expect(find.text('Size'), findsOneWidget);
    expect(find.text('Upload Avatar'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('shows success snackbar when upload succeeds', (tester) async {
    final cubit = TestProfileImageUploadCubit(
      UploadProfileImageUseCase(
        ProfileRepositoryFake(
          mode: MockProfileImageUploadMode.success,
        ),
      ),
    );

    getIt.registerFactory<ProfileImageUploadCubit>(() => cubit);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileImageUploadDemoPage(),
      ),
    );

    cubit.seed(
      const ProfileImageUploadState(
        status: ProfileImageUploadStatus.success,
        lastUploadResult: ProfileImageUploadResult(
          type: ProfileImageType.avatar,
          url: 'mock://avatar/avatar.jpg',
          key: 'avatar-key',
        ),
      ),
    );

    await tester.pump();

    expect(
      find.text('Avatar image uploaded successfully.'),
      findsOneWidget,
    );
  });

  testWidgets('shows failure snackbar when upload fails', (tester) async {
    final cubit = TestProfileImageUploadCubit(
      UploadProfileImageUseCase(
        ProfileRepositoryFake(
          mode: MockProfileImageUploadMode.success,
        ),
      ),
    );

    getIt.registerFactory<ProfileImageUploadCubit>(() => cubit);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileImageUploadDemoPage(),
      ),
    );

    cubit.seed(
      const ProfileImageUploadState(
        status: ProfileImageUploadStatus.failure,
        errorMessage: 'Upload failed',
      ),
    );

    await tester.pump();

    expect(find.text('Upload failed'), findsOneWidget);
  });
}