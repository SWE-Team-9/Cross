import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/repositories/trackManagementRepositoryFake.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/deleteTrackUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackMetadataUseCase.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/updateTrackVisibilityUseCase.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/trackManagementCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/TrackManagementDemoPage.dart';

void main() {
  group('TrackManagementDemoPage', () {
    testWidgets('renders demo page with seeded track', (tester) async {
      final repository = TrackManagementRepositoryFake(
        mode: MockTrackManagementMode.success,
      );

      final cubit = TrackManagementCubit(
        UpdateTrackMetadataUseCase(repository),
        UpdateTrackVisibilityUseCase(repository),
        DeleteTrackUseCase(repository),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TrackManagementCubit>.value(
            value: cubit,
            child: const TrackManagementDemoPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Track Management Demo'), findsOneWidget);
      expect(find.text('Current Track'), findsOneWidget);
      expect(find.text('Edit metadata'), findsOneWidget);
      expect(find.text('Visibility'), findsOneWidget);
      expect(find.text('Danger Zone'), findsOneWidget);
      expect(find.text('Delete Track'), findsWidgets);

      await cubit.close();
    });
  });
}
