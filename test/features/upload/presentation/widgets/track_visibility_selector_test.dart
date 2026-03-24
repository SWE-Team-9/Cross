import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/TrackManagementVisibility.dart';
import 'package:soundcloud_clone/features/upload/presentation/widgets/TrackVisibilitySelector.dart';

void main() {
  group('TrackVisibilitySelector', () {
    testWidgets('renders both visibility options and triggers callback',
        (tester) async {
      TrackManagementVisibility? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackVisibilitySelector(
              value: TrackManagementVisibility.publicTrack,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);

      await tester.tap(find.text('Private'));
      await tester.pump();

      expect(selectedValue, TrackManagementVisibility.privateTrack);
    });
  });
}
