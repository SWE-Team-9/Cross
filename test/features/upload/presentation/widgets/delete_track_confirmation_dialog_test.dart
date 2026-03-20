import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/presentation/widgets/DeleteTrackConfirmationDialog.dart';

void main() {
  group('DeleteTrackConfirmationDialog', () {
    testWidgets('renders title, content, and actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeleteTrackConfirmationDialog(
              trackTitle: 'Demo Track',
            ),
          ),
        ),
      );

      expect(find.text('Delete Track'), findsOneWidget);
      expect(find.textContaining('Demo Track'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
