import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/track_management_repository_fake.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_form.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
import 'package:soundcloud_clone/features/upload/domain/repositories/track_management_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/delete_track_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_metadata_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/update_track_visibility_usecase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_state.dart';

class TestTrackManagementCubit extends TrackManagementCubit {
  TestTrackManagementCubit(
    super.updateTrackMetadataUseCase,
    super.updateTrackVisibilityUseCase,
    super.deleteTrackUseCase,
  );

  void seed(TrackManagementState state) {
    emit(state);
  }
}

class _StaleMetadataRepository implements TrackManagementRepository {
  const _StaleMetadataRepository();

  @override
  Future<void> deleteTrack({required String trackId}) async {}

  @override
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  }) async {
    return ManagedTrack(
      id: trackId,
      title: 'stale-title',
      description: null,
      genreName: 'Ambient',
      tags: const <String>['stale'],
      visibility: TrackManagementVisibility.publicTrack,
    );
  }

  @override
  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  }) async {
    return ManagedTrack(
      id: trackId,
      title: 'unchanged',
      visibility: visibility,
    );
  }
}

void main() {
  group('TrackManagementCubit', () {
    late ManagedTrack track;

    setUp(() {
      track = const ManagedTrack(
        id: 'track-1',
        title: 'Demo Track',
        description: 'Demo Description',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['demo'],
        visibility: TrackManagementVisibility.publicTrack,
      );
    });

    TestTrackManagementCubit buildCubit({
      MockTrackManagementMode mode = MockTrackManagementMode.success,
    }) {
      final repository = TrackManagementRepositoryFake(mode: mode);

      return TestTrackManagementCubit(
        UpdateTrackMetadataUseCase(repository),
        UpdateTrackVisibilityUseCase(repository),
        DeleteTrackUseCase(repository),
      );
    }

    test('initial state is correct', () {
      final cubit = buildCubit();

      expect(cubit.state, const TrackManagementState());

      cubit.close();
    });

    test('initialize seeds currentTrack and form', () {
      final cubit = buildCubit();

      cubit.initialize(track);

      expect(cubit.state.status, TrackManagementStatus.ready);
      expect(cubit.state.currentTrack, track);
      expect(cubit.state.form, isNotNull);
      expect(cubit.state.form!.title, 'Demo Track');

      cubit.close();
    });

    test('updateTitle updates form title', () {
      final cubit = buildCubit();
      cubit.initialize(track);

      cubit.updateTitle('Edited Track');

      expect(cubit.state.form!.title, 'Edited Track');

      cubit.close();
    });

    test('saveMetadata succeeds', () async {
      final cubit = buildCubit();
      cubit.initialize(track);
      cubit.updateTitle('Edited Track');
      cubit.updateDescription('Edited Description');
      cubit.updateGenre('Electronic');
      cubit.updateTagsFromInput('edited, demo');

      await cubit.saveMetadata();

      expect(cubit.state.status, TrackManagementStatus.success);
      expect(cubit.state.currentTrack!.title, 'Edited Track');
      expect(
        cubit.state.successMessage,
        'Track details updated successfully.',
      );

      await cubit.close();
    });

    test('saveMetadata keeps submitted metadata when API responds stale',
        () async {
      final cubit = TestTrackManagementCubit(
        UpdateTrackMetadataUseCase(const _StaleMetadataRepository()),
        UpdateTrackVisibilityUseCase(const _StaleMetadataRepository()),
        DeleteTrackUseCase(const _StaleMetadataRepository()),
      );
      cubit.initialize(track);
      cubit.updateTitle('Edited Track');
      cubit.updateDescription('Edited Description');
      cubit.updateGenre('Electronic');
      cubit.updateTagsFromInput('edited, demo');

      await cubit.saveMetadata();

      expect(cubit.state.status, TrackManagementStatus.success);
      expect(cubit.state.currentTrack!.title, 'Edited Track');
      expect(cubit.state.currentTrack!.description, 'Edited Description');
      expect(cubit.state.currentTrack!.genreName, 'Electronic');
      expect(cubit.state.currentTrack!.tags, const <String>['edited', 'demo']);

      await cubit.close();
    });

    test('saveMetadata fails on validation error', () async {
      final cubit = buildCubit();
      cubit.initialize(track);
      cubit.updateTitle('   ');

      await cubit.saveMetadata();

      expect(cubit.state.status, TrackManagementStatus.failure);
      expect(cubit.state.errorMessage, 'Title is required.');

      await cubit.close();
    });

    test('saveVisibility succeeds', () async {
      final cubit = buildCubit();
      cubit.initialize(track);
      cubit.updateVisibility(TrackManagementVisibility.privateTrack);

      await cubit.saveVisibility();

      expect(cubit.state.status, TrackManagementStatus.success);
      expect(
        cubit.state.currentTrack!.visibility,
        TrackManagementVisibility.privateTrack,
      );
      expect(
        cubit.state.successMessage,
        'Track visibility updated successfully.',
      );

      await cubit.close();
    });

    test('deleteTrack succeeds', () async {
      final cubit = buildCubit();
      cubit.initialize(track);

      await cubit.deleteTrack();

      expect(cubit.state.status, TrackManagementStatus.deleted);
      expect(cubit.state.currentTrack!.isDeleted, isTrue);
      expect(cubit.state.successMessage, 'Track deleted successfully.');

      await cubit.close();
    });

    test('failOnce mode fails first then succeeds', () async {
      final cubit = buildCubit(mode: MockTrackManagementMode.failOnce);
      cubit.initialize(track);
      cubit.updateTitle('Edited Track');

      await cubit.saveMetadata();

      expect(cubit.state.status, TrackManagementStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Mock track action failed once'),
      );

      await cubit.saveMetadata();

      expect(cubit.state.status, TrackManagementStatus.success);
      expect(cubit.state.currentTrack!.title, 'Edited Track');

      await cubit.close();
    });

    test('resetForm restores form from currentTrack', () {
      final cubit = buildCubit();
      cubit.initialize(track);
      cubit.updateTitle('Changed');

      cubit.resetForm();

      expect(cubit.state.form!.title, 'Demo Track');

      cubit.close();
    });

    test('clearFeedback removes messages and restores ready state', () {
      final cubit = buildCubit();
      cubit.seed(
        TrackManagementState(
          status: TrackManagementStatus.failure,
          currentTrack: track,
          form: const TrackManagementState().form,
          errorMessage: 'Error',
        ).copyWith(
          form: cubit.state.form,
        ),
      );

      cubit.initialize(track);
      cubit.seed(
        cubit.state.copyWith(
          status: TrackManagementStatus.failure,
          errorMessage: 'Error',
        ),
      );

      cubit.clearFeedback();

      expect(cubit.state.status, TrackManagementStatus.ready);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.successMessage, isNull);

      cubit.close();
    });
  });
}
