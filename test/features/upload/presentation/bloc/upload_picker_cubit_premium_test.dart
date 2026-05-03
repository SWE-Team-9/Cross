import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/core/errors/failure.dart';
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
  group('UploadPickerCubit premium upload checks', () {
    late _FakeUploadRepository uploadRepository;
    late _FakeSubscriptionRepository subscriptionRepository;
    late _FakeTrackManagementRepository trackManagementRepository;
    late _FakeTrackStatusRepository trackStatusRepository;
    late UploadPickerCubit cubit;

    setUp(() {
      uploadRepository = _FakeUploadRepository();
      subscriptionRepository = _FakeSubscriptionRepository();
      trackManagementRepository = _FakeTrackManagementRepository();
      trackStatusRepository = _FakeTrackStatusRepository();

      cubit = UploadPickerCubit(
        PickAudioFileUseCase(uploadRepository),
        uploadRepository,
        WatchTrackProcessingStatusUseCase(trackStatusRepository),
        UpdateTrackVisibilityUseCase(trackManagementRepository),
        subscriptionRepository,
        const CheckUploadLimitUseCase(),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('blocks upload when no audio file is selected', () async {
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(cubit.state.errorMessage, 'Please select an audio file first.');
      expect(subscriptionRepository.getMySubscriptionCalls, 0);
      expect(uploadRepository.uploadTrackCalls, 0);
    });

    test('blocks blank title before checking subscription', () async {
      await cubit.pickAudioFile();

      await cubit.uploadSelectedFile(title: '   ');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Please enter a track title before uploading.',
      );
      expect(subscriptionRepository.getMySubscriptionCalls, 0);
      expect(uploadRepository.uploadTrackCalls, 0);
    });

    test('blocks exhausted free upload limit with upgrade message', () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'FREE',
        subscriptionType: 'FREE',
        subscriptionStatus: 'ACTIVE',
        isPremium: false,
        uploadLimit: 3,
        uploadedTracks: 3,
        remainingUploads: 0,
      );

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Upload limit reached. Upgrade to Pro to upload more tracks.',
      );
      expect(subscriptionRepository.getMySubscriptionCalls, 1);
      expect(uploadRepository.uploadTrackCalls, 0);
    });

    test('blocks inactive premium subscription with billing message', () async {
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

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Your subscription is not active. Please update your billing status to upload.',
      );
      expect(uploadRepository.uploadTrackCalls, 0);
    });

    test('blocks exhausted premium finite quota with detailed message',
        () async {
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

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Upload limit reached for Pro. You have used 100/100 uploads.',
      );
      expect(uploadRepository.uploadTrackCalls, 0);
    });

    test('allows active free user with remaining uploads', () async {
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
        trackId: 'track-1',
        status: 'FINISHED',
        secretToken: 'secret-token',
      );

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: '  Midnight Drive  ');

      expect(cubit.state.status, UploadPickerStatus.success);
      expect(cubit.state.uploadedTrackId, 'track-1');
      expect(cubit.state.processingStatus, TrackStatus.FINISHED.name);
      expect(
        cubit.state.uploadedVisibility,
        TrackManagementVisibility.privateTrack,
      );
      expect(cubit.state.privateShareToken, 'secret-token');

      expect(subscriptionRepository.getMySubscriptionCalls, 1);
      expect(uploadRepository.uploadTrackCalls, 1);
      expect(uploadRepository.lastUploadTitle, 'Midnight Drive');
    });

    test('allows unlimited premium user even when remainingUploads is zero',
        () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'GO_PLUS',
        subscriptionType: 'GO_PLUS',
        subscriptionStatus: 'ACTIVE',
        planName: 'GO+',
        isPremium: true,
        isUnlimited: true,
        uploadLimit: 0,
        uploadLimitDisplay: '',
        uploadedTracks: 500,
        remainingUploads: 0,
      );

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'FINISHED',
      );

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.success);
      expect(uploadRepository.uploadTrackCalls, 1);
    });

    test('allows premium user when uploadedTracks is below server uploadLimit',
        () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        planName: 'Pro',
        isPremium: true,
        uploadLimit: 100,
        uploadLimitDisplay: '100',
        uploadedTracks: 99,
        remainingUploads: 0,
      );

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'FINISHED',
      );

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.success);
      expect(uploadRepository.uploadTrackCalls, 1);
    });

    test('emits subscription check failure when subscription request fails',
        () async {
      subscriptionRepository.getMySubscriptionError = Exception('Network down');

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Failed to check subscription. Please try again.',
      );
      expect(uploadRepository.uploadTrackCalls, 0);
    });

    test('passes normalized upload metadata and parsed tags to repository',
        () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 0,
        remainingUploads: 100,
      );

      final releaseDate = DateTime.parse('2026-04-01T00:00:00.000Z');

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'FINISHED',
      );

      await cubit.pickAudioFile();

      await cubit.uploadSelectedFile(
        title: '  Midnight Drive  ',
        genre: '  Electronic  ',
        tagsInput: ' edm, chill, EDM, , night ',
        description: '  Demo description  ',
        releaseDate: releaseDate,
      );

      expect(cubit.state.status, UploadPickerStatus.success);
      expect(uploadRepository.lastUploadTitle, 'Midnight Drive');
      expect(uploadRepository.lastGenre, 'Electronic');
      expect(uploadRepository.lastDescription, 'Demo description');
      expect(uploadRepository.lastReleaseDate, releaseDate);
      expect(uploadRepository.lastTags, <String>['edm', 'chill', 'night']);
    });

    test('updates upload progress from repository callback', () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 0,
        remainingUploads: 100,
      );

      uploadRepository.progressValues = const <double>[0.2, 0.7, 1.0];
      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'FINISHED',
      );

      final emittedStates = <UploadPickerState>[];
      final subscription = cubit.stream.listen(emittedStates.add);

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      await subscription.cancel();

      expect(
        emittedStates.map((state) => state.uploadProgress).whereType<double>(),
        containsAllInOrder(<double>[0.2, 0.7, 1.0]),
      );
      expect(cubit.state.status, UploadPickerStatus.success);
    });

    test('resolves public visibility after a finished upload', () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 0,
        remainingUploads: 100,
      );

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'FINISHED',
        secretToken: 'secret-token',
      );

      trackManagementRepository.updatedTrack = const ManagedTrack(
        id: 'track-1',
        title: 'Midnight Drive',
        visibility: TrackManagementVisibility.publicTrack,
        status: TrackStatus.FINISHED,
      );

      await cubit.pickAudioFile();

      await cubit.uploadSelectedFile(
        title: 'Midnight Drive',
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(cubit.state.status, UploadPickerStatus.success);
      expect(
        cubit.state.uploadedVisibility,
        TrackManagementVisibility.publicTrack,
      );
      expect(cubit.state.privateShareToken, isNull);
      expect(trackManagementRepository.updateTrackVisibilityCalls, 1);
      expect(trackManagementRepository.lastTrackId, 'track-1');
      expect(
        trackManagementRepository.lastVisibility,
        TrackManagementVisibility.publicTrack,
      );
    });

    test('watches processing upload until finished', () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 0,
        remainingUploads: 100,
      );

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'PROCESSING',
      );

      trackStatusRepository.statuses = const <TrackProcessingStatus>[
        TrackProcessingStatus(
          trackId: 'track-1',
          status: TrackStatus.FINISHED,
        ),
      ];

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.success);
      expect(cubit.state.processingStatus, TrackStatus.FINISHED.name);
      expect(trackStatusRepository.getTrackStatusCalls, 1);
    });

    test('fails when processing upload returns failed status', () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 0,
        remainingUploads: 100,
      );

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'PROCESSING',
      );

      trackStatusRepository.statuses = const <TrackProcessingStatus>[
        TrackProcessingStatus(
          trackId: 'track-1',
          status: TrackStatus.FAILED,
        ),
      ];

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(cubit.state.errorMessage,
          'Track processing failed. Please try again.');
      expect(cubit.state.processingStatus, TrackStatus.FAILED.name);
    });

    test('fails immediately when initial upload status is failed', () async {
      subscriptionRepository.subscription = const Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        uploadLimit: 100,
        uploadedTracks: 0,
        remainingUploads: 100,
      );

      uploadRepository.uploadResult = const UploadTrackResult(
        trackId: 'track-1',
        status: 'FAILED',
      );

      await cubit.pickAudioFile();
      await cubit.uploadSelectedFile(title: 'Midnight Drive');

      expect(cubit.state.status, UploadPickerStatus.failure);
      expect(cubit.state.errorMessage,
          'Track processing failed. Please try again.');
    });

    test('clearSelection resets upload picker state', () async {
      await cubit.pickAudioFile();

      cubit.clearSelection();

      expect(cubit.state.status, UploadPickerStatus.initial);
      expect(cubit.state.pickedAudioFile, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.uploadedTrackId, isNull);
      expect(cubit.state.processingStatus, isNull);
      expect(cubit.state.uploadProgress, isNull);
      expect(cubit.state.uploadedVisibility, isNull);
      expect(cubit.state.privateShareToken, isNull);
      expect(cubit.state.failureType, UploadPickerFailureType.none);
    });
  });
}

class _FakeUploadRepository implements UploadRepository {
  PickedAudioFile? pickedAudioFile = const PickedAudioFile(
    name: 'midnight-drive.mp3',
    extension: 'mp3',
    sizeInBytes: 1024,
    path: '/tmp/midnight-drive.mp3',
  );

  UploadTrackResult uploadResult = const UploadTrackResult(
    trackId: 'track-1',
    status: 'FINISHED',
    secretToken: 'secret-token',
  );

  List<double> progressValues = const <double>[];

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

    for (final progress in progressValues) {
      onProgress?.call(progress);
      await Future<void>.delayed(Duration.zero);
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
    planCode: 'PRO',
    subscriptionType: 'PRO',
    subscriptionStatus: 'ACTIVE',
    isPremium: true,
    uploadLimit: 100,
    uploadedTracks: 0,
    remainingUploads: 100,
  );

  Object? getMySubscriptionError;

  int getMySubscriptionCalls = 0;
  int getPlansCalls = 0;
  int createCheckoutCalls = 0;
  int subscribeCalls = 0;
  int openBillingPortalSessionCalls = 0;
  int getInvoicesCalls = 0;
  int cancelSubscriptionCalls = 0;
  int resumeSubscriptionCalls = 0;
  int changePlanCalls = 0;
  int cancelPlanChangeCalls = 0;
  int getOfflineTrackEntitlementCalls = 0;

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
    getPlansCalls++;
    return const <Plan>[];
  }

  @override
  Future<String> createCheckout(String plan) async {
    createCheckoutCalls++;
    return 'https://checkout.example.com/$plan';
  }

  @override
  Future<String> subscribe(String plan) async {
    subscribeCalls++;
    return 'https://subscribe.example.com/$plan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    openBillingPortalSessionCalls++;
    return const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    );
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    getInvoicesCalls++;
    return const <BillingInvoice>[];
  }

  @override
  Future<Subscription> cancelSubscription() async {
    cancelSubscriptionCalls++;
    subscription = subscription.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
    );
    return subscription;
  }

  @override
  Future<Subscription> resumeSubscription() async {
    resumeSubscriptionCalls++;
    subscription = subscription.copyWith(
      cancelAtPeriodEnd: false,
      canResume: false,
    );
    return subscription;
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    changePlanCalls++;
    subscription = subscription.copyWith(
      planCode: plan,
      subscriptionType: plan,
      isPremium: plan.trim().toUpperCase() != 'FREE',
    );
    return subscription;
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    cancelPlanChangeCalls++;
    subscription = subscription.copyWith(clearPendingDowngrade: true);

    return subscription;
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    getOfflineTrackEntitlementCalls++;
    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: subscription.planCode,
    );
  }
}

class _FakeTrackManagementRepository implements TrackManagementRepository {
  ManagedTrack updatedTrack = const ManagedTrack(
    id: 'track-1',
    title: 'Midnight Drive',
    visibility: TrackManagementVisibility.publicTrack,
    status: TrackStatus.FINISHED,
  );

  Object? updateTrackVisibilityError;

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

    final error = updateTrackVisibilityError;
    if (error != null) {
      throw error;
    }

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
