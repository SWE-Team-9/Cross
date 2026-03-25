import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/presentation/widgets/TrackManagementActionsSheet.dart';

void main() {
  group('TrackManagementActionsSheet', () {
    testWidgets('renders actions and triggers callbacks', (tester) async {
      int editTapCount = 0;
      int visibilityTapCount = 0;
      int deleteTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackManagementActionsSheet(
              onEditTap: () => editTapCount++,
              onVisibilityTap: () => visibilityTapCount++,
              onDeleteTap: () => deleteTapCount++,
            ),
          ),
        ),
      );

      expect(find.text('Edit metadata'), findsOneWidget);
      expect(find.text('Change visibility'), findsOneWidget);
      expect(find.text('Delete track'), findsOneWidget);

      await tester.tap(find.text('Edit metadata'));
      await tester.pump();

      await tester.tap(find.text('Change visibility'));
      await tester.pump();

      await tester.tap(find.text('Delete track'));
      await tester.pump();

      expect(editTapCount, 1);
      expect(visibilityTapCount, 1);
      expect(deleteTapCount, 1);
    });
  });
}
