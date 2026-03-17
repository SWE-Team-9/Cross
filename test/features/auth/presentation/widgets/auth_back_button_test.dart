import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/presentation/widgets/auth_back_button.dart';

void main() {
  group('AuthBackButton', () {
    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthBackButton(),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('pops when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: AuthBackButton(),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthBackButton), findsOneWidget);

      await tester.tap(find.byType(AuthBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(AuthBackButton), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}