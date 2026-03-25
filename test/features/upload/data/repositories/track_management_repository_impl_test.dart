import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/upload/data/datasources/trackManagementRemoteDataSource.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/trackManagementRepositoryImpl.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/ManagedTrack.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementForm.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';

class MockTrackManagementRemoteDataSource extends Mock
    implements TrackManagementRemoteDataSource {}

void main() {
  late MockTrackManagementRemoteDataSource mockRemoteDataSource;
  late TrackManagementRepositoryImpl repository;

  const track = ManagedTrack(
    id: 'track-1',
    title: 'Midnight Echoes',
    description: 'Demo track',
    genreId: 1,
    genreName: 'Ambient',
    tags: <String>['ambient'],
    visibility: TrackManagementVisibility.publicTrack,
    durationInSeconds: 212,
  );

  const form = TrackManagementForm(
    title: 'City Lights',
    description: 'Updated description',
    genreId: 2,
    tags: <String>['night', 'synth'],
    visibility: TrackManagementVisibility.privateTrack,
  );
  setUp(() {
    mockRemoteDataSource = MockTrackManagementRemoteDataSource();
    repository = TrackManagementRepositoryImpl(mockRemoteDataSource);
  });

  group('updateTrackMetadata', () {
    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.updateTrackMetadata(
            trackId: 'track-1',
            form: form,
          )).thenAnswer((_) async => track);

      final result = await repository.updateTrackMetadata(
        trackId: 'track-1',
        form: form,
      );

      expect(result, track);
      verify(() => mockRemoteDataSource.updateTrackMetadata(
            trackId: 'track-1',
            form: form,
          )).called(1);
    });
  });

  group('updateTrackVisibility', () {
    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.updateTrackVisibility(
            trackId: 'track-1',
            visibility: TrackManagementVisibility.privateTrack,
          )).thenAnswer((_) async => track);

      final result = await repository.updateTrackVisibility(
        trackId: 'track-1',
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(result, track);
      verify(() => mockRemoteDataSource.updateTrackVisibility(
            trackId: 'track-1',
            visibility: TrackManagementVisibility.privateTrack,
          )).called(1);
    });
  });

  group('deleteTrack', () {
    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.deleteTrack(trackId: 'track-1'))
          .thenAnswer((_) async {});

      await repository.deleteTrack(trackId: 'track-1');

      verify(() => mockRemoteDataSource.deleteTrack(trackId: 'track-1'))
          .called(1);
    });
  });
}
