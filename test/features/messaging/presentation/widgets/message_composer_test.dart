import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_composer.dart';

void main() {
  group('MessageComposer', () {
    Future<void> pumpComposer(
      WidgetTester tester, {
      required bool isSending,
      required ValueChanged<String> onSend,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageComposer(
              isSending: isSending,
              onSend: onSend,
            ),
          ),
        ),
      );
    }

    testWidgets('shows input hint and send icon', (tester) async {
      await pumpComposer(
        tester,
        isSending: false,
        onSend: (_) {},
      );

      expect(find.text('Write a message...'), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('calls onSend with trimmed text and clears field',
        (tester) async {
      String? sentText;

      await pumpComposer(
        tester,
        isSending: false,
        onSend: (text) => sentText = text,
      );

      await tester.enterText(find.byType(TextField), '  Hello there  ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sentText, 'Hello there');
      expect(find.text('Hello there'), findsNothing);
    });

    testWidgets('does not call onSend for blank text', (tester) async {
      var calls = 0;

      await pumpComposer(
        tester,
        isSending: false,
        onSend: (_) => calls++,
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('does not call onSend while sending', (tester) async {
      var calls = 0;

      await pumpComposer(
        tester,
        isSending: true,
        onSend: (_) => calls++,
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      expect(calls, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('submitting keyboard sends message', (tester) async {
      String? sentText;

      await pumpComposer(
        tester,
        isSending: false,
        onSend: (text) => sentText = text,
      );

      await tester.enterText(find.byType(TextField), 'Keyboard send');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(sentText, 'Keyboard send');
    });
  });
}
