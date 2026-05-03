import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/errors/upload_picker_exceptions.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_audio_file.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/picked_image_file.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_form.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_processing_status.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/i_track_status_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/track_management_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/upload_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/check_upload_limit_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/pick_audi_file_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_visibility_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/watch_track_processing_status_use_case.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_state.dart';

void main() {
  const pickedAudioFile = PickedAudioFile(
    name: 'selected_audio.mp3',
    extension: 'mp3',
    sizeInBytes: 4096,
    path: '/storage/emulated/0/Download/selected_audio.mp3',
  );

  group('UploadPickerCubit', () {
    late _FakeUploadRepository uploadRepository;
    late _FakeTrackStatusRepository trackStatusRepository;
    late _FakeTrackManagementRepository trackManagementRepository;
    late _FakeSubscriptionRepository subscriptionRepository;

    UploadPickerCubit buildCubit() {
      return UploadPickerCubit(
        PickAudioFileUseCase(uploadRepository),
        uploadRepository,
        WatchTrackProcessingStatusUseCase(trackStatusRepository),
        UpdateTrackVisibilityUseCase(trackManagementRepository),
        subscriptionRepository,
        const CheckUploadLimitUseCase(),
      );
    }

    setUp(() {
      uploadRepository = _FakeUploadRepository();
      trackStatusRepository = _FakeTrackStatusRepository();
      trackManagementRepository = _FakeTrackManagementRepository();
      subscriptionRepository = _FakeSubscriptionRepository();
    });

    test('initial state is UploadPickerState()', () async {
      final cubit = buildCubit();

      expect(cubit.state, const UploadPickerState());

      await cubit.close();
    });

    blocTest<UploadPickerCubit, UploadPickerState>(
      'pickAudioFile emits picking then ready when file is picked',
      build: buildCubit,
      act: (cubit) => cubit.pickAudioFile(),
      expect: () => const <UploadPickerState>[
        UploadPickerState(status: UploadPickerStatus.picking),
        UploadPickerState(
          status: UploadPickerStatus.ready,
          pickedAudioFile: pickedAudioFile,
        ),
      ],
      verify: (_) {
        expect(uploadRepository.pickAudioFileCalls, 1);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'pickAudioFile emits picking then cancelled when user cancels',
      build: () {
        uploadRepository.pickedAudioFile = null;
        return buildCubit();
      },
      act: (cubit) => cubit.pickAudioFile(),
      expect: () => const <UploadPickerState>[
        UploadPickerState(status: UploadPickerStatus.picking),
        UploadPickerState(status: UploadPickerStatus.cancelled),
      ],
      verify: (_) {
        expect(uploadRepository.pickAudioFileCalls, 1);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'pickAudioFile emits permission failure when permission is permanently denied',
      build: () {
        uploadRepository.pickAudioFileError =
            const UploadPickerPermissionPermanentlyDeniedException(
          'Audio file permission is permanently denied. Please enable it from system settings.',
        );

        return buildCubit();
      },
      act: (cubit) => cubit.pickAudioFile(),
      expect: () => const <UploadPickerState>[
        UploadPickerState(status: UploadPickerStatus.picking),
        UploadPickerState(
          status: UploadPickerStatus.failure,
          errorMessage:
              'Audio file permission is permanently denied. Please enable it from system settings.',
          failureType: UploadPickerFailureType.permissionPermanentlyDenied,
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'pickAudioFile emits readable failure when picker throws',
      build: () {
        uploadRepository.pickAudioFileError =
            Exception('Failed to pick audio file');
        return buildCubit();
      },
      act: (cubit) => cubit.pickAudioFile(),
      expect: () => const <UploadPickerState>[
        UploadPickerState(status: UploadPickerStatus.picking),
        UploadPickerState(
          status: UploadPickerStatus.failure,
          errorMessage: 'Failed to pick audio file',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits failure when no file is selected',
      build: buildCubit,
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          errorMessage: 'Please select an audio file first.',
        ),
      ],
      verify: (_) {
        expect(subscriptionRepository.getMySubscriptionCalls, 0);
        expect(uploadRepository.uploadTrackCalls, 0);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits failure when title is empty',
      build: buildCubit,
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: '   '),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'Please enter a track title before uploading.',
        ),
      ],
      verify: (_) {
        expect(subscriptionRepository.getMySubscriptionCalls, 0);
        expect(uploadRepository.uploadTrackCalls, 0);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits failure when title exceeds api limit',
      build: buildCubit,
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'a' * 101),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'Title must be 100 characters or fewer.',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits failure when description exceeds api limit',
      build: buildCubit,
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(
        title: 'My Track',
        description: 'a' * 5001,
      ),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'Description must be 5000 characters or fewer.',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits failure when tag exceeds api limit',
      build: buildCubit,
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(
        title: 'My Track',
        tagsInput: 'short, ${'a' * 31}',
      ),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'Each tag must be 30 characters or fewer.',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits subscription check failure when subscription request fails',
      build: () {
        subscriptionRepository.getMySubscriptionError =
            Exception('Network down');
        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'Failed to check subscription. Please try again.',
        ),
      ],
      verify: (_) {
        expect(subscriptionRepository.getMySubscriptionCalls, 1);
        expect(uploadRepository.uploadTrackCalls, 0);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile blocks exhausted free upload quota',
      build: () {
        subscriptionRepository.subscription = const Subscription(
          planCode: 'FREE',
          subscriptionType: 'FREE',
          subscriptionStatus: 'ACTIVE',
          isPremium: false,
          uploadLimit: 3,
          uploadedTracks: 3,
          remainingUploads: 0,
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage:
              'Upload limit reached. Upgrade to Pro to upload more tracks.',
        ),
      ],
      verify: (_) {
        expect(subscriptionRepository.getMySubscriptionCalls, 1);
        expect(uploadRepository.uploadTrackCalls, 0);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile blocks inactive premium subscription',
      build: () {
        subscriptionRepository.subscription = const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'INACTIVE',
          planName: 'Pro',
          isPremium: true,
          uploadLimit: 100,
          uploadLimitDisplay: '100',
          uploadedTracks: 10,
          remainingUploads: 90,
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage:
              'Your subscription is not active. Please update your billing status to upload.',
        ),
      ],
      verify: (_) {
        expect(uploadRepository.uploadTrackCalls, 0);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile blocks exhausted premium finite quota',
      build: () {
        subscriptionRepository.subscription = const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          planName: 'Pro',
          isPremium: true,
          uploadLimit: 100,
          uploadLimitDisplay: '100',
          uploadedTracks: 100,
          remainingUploads: 0,
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage:
              'Upload limit reached for Pro. You have used 100/100 uploads.',
        ),
      ],
      verify: (_) {
        expect(uploadRepository.uploadTrackCalls, 0);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits uploading, processing, success when upload finishes immediately',
      build: () {
        subscriptionRepository.subscription = const Subscription(
          planCode: 'FREE',
          subscriptionType: 'FREE',
          subscriptionStatus: 'ACTIVE',
          isPremium: false,
          uploadLimit: 3,
          uploadedTracks: 1,
          remainingUploads: 2,
        );

        uploadRepository.uploadResult = const UploadTrackResult(
          trackId: 'track-123',
          status: 'FINISHED',
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(
        title: '  My Track  ',
        tagsInput: 'lofi, chill, LOFI, , night',
        description: '  Demo description  ',
        genre: '  Electronic  ',
      ),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
        UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
      ],
      verify: (_) {
        expect(subscriptionRepository.getMySubscriptionCalls, 1);
        expect(uploadRepository.uploadTrackCalls, 1);
        expect(uploadRepository.lastUploadTitle, 'My Track');
        expect(uploadRepository.lastGenre, 'Electronic');
        expect(uploadRepository.lastDescription, 'Demo description');
        expect(uploadRepository.lastTags, <String>['lofi', 'chill', 'night']);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile allows unlimited premium subscription',
      build: () {
        subscriptionRepository.subscription = const Subscription(
          planCode: 'GO_PLUS',
          subscriptionType: 'GO_PLUS',
          subscriptionStatus: 'ACTIVE',
          planName: 'GO+',
          isPremium: true,
          isUnlimited: true,
          uploadLimit: 0,
          uploadedTracks: 500,
          remainingUploads: 0,
        );

        uploadRepository.uploadResult = const UploadTrackResult(
          trackId: 'track-123',
          status: 'FINISHED',
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
        UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
      ],
      verify: (_) {
        expect(uploadRepository.uploadTrackCalls, 1);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile stores private share token when returned by upload',
      build: () {
        uploadRepository.uploadResult = const UploadTrackResult(
          trackId: 'track-123',
          status: 'FINISHED',
          secretToken: 'secret-123',
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
          privateShareToken: 'secret-123',
        ),
        UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
          privateShareToken: 'secret-123',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile resolves public visibility after upload finishes',
      build: () {
        uploadRepository.uploadResult = const UploadTrackResult(
          trackId: 'track-123',
          status: 'FINISHED',
          secretToken: 'secret-123',
        );

        trackManagementRepository.updatedTrack = const ManagedTrack(
          id: 'track-123',
          title: 'My Track',
          visibility: TrackManagementVisibility.publicTrack,
          status: TrackStatus.FINISHED,
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(
        title: 'My Track',
        visibility: TrackManagementVisibility.publicTrack,
      ),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
        ),
        UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.publicTrack,
        ),
      ],
      verify: (_) {
        expect(trackManagementRepository.updateTrackVisibilityCalls, 1);
        expect(trackManagementRepository.lastTrackId, 'track-123');
        expect(
          trackManagementRepository.lastVisibility,
          TrackManagementVisibility.publicTrack,
        );
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile watches processing upload until finished',
      build: () {
        uploadRepository.uploadResult = const UploadTrackResult(
          trackId: 'track-123',
          status: 'PROCESSING',
        );

        trackStatusRepository.statuses = const <TrackProcessingStatus>[
          TrackProcessingStatus(
            trackId: 'track-123',
            status: TrackStatus.FINISHED,
          ),
        ];

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'PROCESSING',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
        UploadPickerState(
          status: UploadPickerStatus.success,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FINISHED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
      ],
      verify: (_) {
        expect(trackStatusRepository.getTrackStatusCalls, 1);
      },
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits failure when processing status fails immediately',
      build: () {
        uploadRepository.uploadResult = const UploadTrackResult(
          trackId: 'track-123',
          status: 'FAILED',
        );

        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.processing,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FAILED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
        ),
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          uploadedTrackId: 'track-123',
          processingStatus: 'FAILED',
          uploadedVisibility: TrackManagementVisibility.privateTrack,
          errorMessage: 'Track processing failed. Please try again.',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'uploadSelectedFile emits readable failure when upload repository throws',
      build: () {
        uploadRepository.uploadTrackError = Exception('Network error');
        return buildCubit();
      },
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
      ),
      act: (cubit) => cubit.uploadSelectedFile(title: 'My Track'),
      expect: () => const <UploadPickerState>[
        UploadPickerState(
          status: UploadPickerStatus.uploading,
          pickedAudioFile: pickedAudioFile,
        ),
        UploadPickerState(
          status: UploadPickerStatus.failure,
          pickedAudioFile: pickedAudioFile,
          errorMessage: 'Network error',
        ),
      ],
    );

    blocTest<UploadPickerCubit, UploadPickerState>(
      'clearSelection resets state to initial',
      build: buildCubit,
      seed: () => const UploadPickerState(
        status: UploadPickerStatus.ready,
        pickedAudioFile: pickedAudioFile,
        errorMessage: 'old error',
        uploadedTrackId: 'track-123',
        processingStatus: 'FINISHED',
        uploadProgress: 0.5,
        uploadedVisibility: TrackManagementVisibility.privateTrack,
        privateShareToken: 'secret-123',
      ),
      act: (cubit) => cubit.clearSelection(),
      expect: () => const <UploadPickerState>[
        UploadPickerState(status: UploadPickerStatus.initial),
      ],
    );

    test('isBusy is true when status is picking, uploading, or processing', () {
      for (final status in <UploadPickerStatus>[
        UploadPickerStatus.picking,
        UploadPickerStatus.uploading,
        UploadPickerStatus.processing,
      ]) {
        expect(UploadPickerState(status: status).isBusy, isTrue);
      }
    });

    test('isBusy is false for all other statuses', () {
      for (final status in <UploadPickerStatus>[
        UploadPickerStatus.initial,
        UploadPickerStatus.ready,
        UploadPickerStatus.success,
        UploadPickerStatus.cancelled,
        UploadPickerStatus.failure,
      ]) {
        expect(UploadPickerState(status: status).isBusy, isFalse);
      }
    });

    test('hasSelection is true when pickedAudioFile is set', () {
      expect(
        const UploadPickerState(pickedAudioFile: pickedAudioFile).hasSelection,
        isTrue,
      );
    });

    test('hasSelection is false when pickedAudioFile is null', () {
      expect(const UploadPickerState().hasSelection, isFalse);
    });

    test('hasCreatedTrack is true when uploadedTrackId is set', () {
      expect(
        const UploadPickerState(uploadedTrackId: 'track-123').hasCreatedTrack,
        isTrue,
      );
    });

    test('hasCreatedTrack is false when uploadedTrackId is null', () {
      expect(const UploadPickerState().hasCreatedTrack, isFalse);
    });
  });
}

class _FakeUploadRepository implements UploadRepository {
  PickedAudioFile? pickedAudioFile = const PickedAudioFile(
    name: 'selected_audio.mp3',
    extension: 'mp3',
    sizeInBytes: 4096,
    path: '/storage/emulated/0/Download/selected_audio.mp3',
  );

  UploadTrackResult uploadResult = const UploadTrackResult(
    trackId: 'track-123',
    status: 'FINISHED',
  );

  Object? pickAudioFileError;
  Object? uploadTrackError;

  int pickAudioFileCalls = 0;
  int uploadTrackCalls = 0;
  int getTrackStatusCalls = 0;

  PickedAudioFile? lastUploadedFile;
  String? lastUploadTitle;
  PickedImageFile? lastCoverArt;
  String? lastGenre;
  String? lastDescription;
  DateTime? lastReleaseDate;
  List<String> lastTags = const <String>[];

  @override
  Future<PickedAudioFile?> pickAudioFile() async {
    pickAudioFileCalls++;

    final error = pickAudioFileError;
    if (error != null) {
      throw error;
    }

    return pickedAudioFile;
  }

  @override
  Future<UploadTrackResult> uploadTrack({
    required PickedAudioFile file,
    required String title,
    PickedImageFile? coverArt,
    String? genre,
    String? description,
    DateTime? releaseDate,
    List<String> tags = const <String>[],
    UploadProgressCallback? onProgress,
  }) async {
    uploadTrackCalls++;
    lastUploadedFile = file;
    lastUploadTitle = title;
    lastCoverArt = coverArt;
    lastGenre = genre;
    lastDescription = description;
    lastReleaseDate = releaseDate;
    lastTags = List<String>.from(tags);

    final error = uploadTrackError;
    if (error != null) {
      throw error;
    }

    return uploadResult;
  }

  @override
  Future<String> getTrackStatus({
    required String trackId,
  }) async {
    getTrackStatusCalls++;
    return TrackStatus.FINISHED.name;
  }
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  Subscription subscription = const Subscription(
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'ACTIVE',
    isPremium: false,
    uploadLimit: 3,
    uploadedTracks: 0,
    remainingUploads: 3,
  );

  Object? getMySubscriptionError;

  int getMySubscriptionCalls = 0;

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;

    final error = getMySubscriptionError;
    if (error != null) {
      throw error;
    }

    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    return const <Plan>[];
  }

  @override
  Future<String> createCheckout(String plan) async {
    return 'https://checkout.example.com/$plan';
  }

  @override
  Future<String> subscribe(String plan) async {
    return 'https://subscribe.example.com/$plan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    return const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    );
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    return const <BillingInvoice>[];
  }

  @override
  Future<Subscription> cancelSubscription() async {
    subscription = subscription.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
    );

    return subscription;
  }

  @override
  Future<Subscription> resumeSubscription() async {
    subscription = subscription.copyWith(
      cancelAtPeriodEnd: false,
      canResume: false,
    );

    return subscription;
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    subscription = subscription.copyWith(
      planCode: plan,
      subscriptionType: plan,
      isPremium: plan.trim().toUpperCase() != 'FREE',
    );

    return subscription;
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    subscription = subscription.copyWith(clearPendingDowngrade: true);

    return subscription;
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: subscription.planCode,
    );
  }
}

class _FakeTrackManagementRepository implements TrackManagementRepository {
  ManagedTrack updatedTrack = const ManagedTrack(
    id: 'track-123',
    title: 'My Track',
    visibility: TrackManagementVisibility.publicTrack,
    status: TrackStatus.FINISHED,
  );

  int updateTrackMetadataCalls = 0;
  int updateTrackVisibilityCalls = 0;
  int deleteTrackCalls = 0;

  String? lastTrackId;
  TrackManagementVisibility? lastVisibility;

  @override
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  }) async {
    updateTrackMetadataCalls++;
    return updatedTrack.copyWith(id: trackId);
  }

  @override
  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  }) async {
    updateTrackVisibilityCalls++;
    lastTrackId = trackId;
    lastVisibility = visibility;

    return updatedTrack.copyWith(
      id: trackId,
      visibility: visibility,
    );
  }

  @override
  Future<void> deleteTrack({
    required String trackId,
  }) async {
    deleteTrackCalls++;
  }
}

class _FakeTrackStatusRepository implements ITrackStatusRepository {
  List<TrackProcessingStatus> statuses = const <TrackProcessingStatus>[];

  int getTrackStatusCalls = 0;

  @override
  Future<({Failure? failure, TrackProcessingStatus? status})> getTrackStatus(
    String trackId,
  ) async {
    final index = getTrackStatusCalls;
    getTrackStatusCalls++;

    if (statuses.isEmpty) {
      return (
        failure: null,
        status: TrackProcessingStatus(
          trackId: trackId,
          status: TrackStatus.FINISHED,
        ),
      );
    }

    final safeIndex = index >= statuses.length ? statuses.length - 1 : index;

    return (
      failure: null,
      status: statuses[safeIndex],
    );
  }
}
