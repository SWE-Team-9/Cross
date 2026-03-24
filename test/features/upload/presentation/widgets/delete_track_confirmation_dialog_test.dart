import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/presentation/widgets/DeleteTrackConfirmationDialog.dart';

void main() {
  Widget buildApp() {
    return const MaterialApp(
      home: Scaffold(
        body: DeleteTrackConfirmationDialog(
          trackTitle: 'Midnight Echoes',
        ),
      ),
    );
  }

  group('DeleteTrackConfirmationDialog', () {
    testWidgets('renders title, message, and actions', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Delete Track'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Midnight Echoes"? This action cannot be undone from the app.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping Cancel pops false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const DeleteTrackConfirmationDialog(
                        trackTitle: 'Midnight Echoes',
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('tapping Delete pops true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const DeleteTrackConfirmationDialog(
                        trackTitle: 'Midnight Echoes',
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}
