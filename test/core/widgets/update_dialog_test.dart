import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/widgets/update_dialog.dart';

void main() {
  testWidgets('renders optional release sections and allows dismissing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => UpdateDialog(
                    updateData: _updateData(),
                    downloadUrl: 'https://example.com/download',
                    updateType: UpdateType.inApp,
                  ),
                );
              },
              child: const Text('show'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.text('Version 2.0'), findsOneWidget);
    expect(find.text('A better build'), findsOneWidget);
    expect(find.textContaining('New Features'), findsOneWidget);
    expect(find.text('Fresh player'), findsOneWidget);
    expect(find.textContaining('Improvements'), findsOneWidget);
    expect(find.text('Faster library'), findsOneWidget);
    expect(find.textContaining('Bug Fixes'), findsOneWidget);
    expect(find.text('Fixed sharing'), findsOneWidget);

    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    expect(find.text('Version 2.0'), findsNothing);
  });

  testWidgets('mandatory update hides the later action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UpdateDialog(
          updateData: _updateData(
            release: const <String, dynamic>{
              'title': 'Required update',
            },
          ),
          downloadUrl: 'https://example.com/download',
          updateType: UpdateType.inApp,
          isMandatory: true,
        ),
      ),
    );

    expect(find.text('Required update'), findsOneWidget);
    expect(find.text('Maybe Later'), findsNothing);
    expect(find.text('Update Now'), findsOneWidget);
  });
}

Map<String, dynamic> _updateData({Map<String, dynamic>? release}) {
  return <String, dynamic>{
    'download_url': 'https://example.com/download',
    'release': release ??
        const <String, dynamic>{
          'title': 'Version 2.0',
          'subtitle': 'A better build',
          'new_features': ['Fresh player'],
          'improvements': ['Faster library'],
          'bug_fixes': ['Fixed sharing'],
        },
  };
}
