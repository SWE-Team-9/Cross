import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/trackManagementRepositoryFake.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/ManagedTrack.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/deleteTrackUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackMetadataUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackVisibilityUseCase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/trackManagementCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/TrackManagementPage.dart';

void main() {
  group('TrackManagementPage', () {
    testWidgets('renders page with seeded track', (tester) async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.success,
      );

      final cubit = TrackManagementCubit(
        UpdateTrackMetadataUseCase(repository),
        UpdateTrackVisibilityUseCase(repository),
        DeleteTrackUseCase(repository),
      );

      const initialTrack = ManagedTrack(
        id: 'demo-track-001',
        title: 'Midnight Echoes',
        description: 'Sprint 2 local demo track for edit/delete testing.',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['demo', 'sprint2'],
        visibility: TrackManagementVisibility.publicTrack,
        durationInSeconds: 212,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TrackManagementCubit>.value(
            value: cubit,
            child: const TrackManagementPage(
              initialTrack: initialTrack,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Track Management'), findsOneWidget);
      expect(find.text('Current Track'), findsOneWidget);
      expect(find.text('Visibility'), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Delete Track'), findsWidgets);

      await cubit.close();
    });
  });
}
