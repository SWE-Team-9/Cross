import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/repeat_mode_button.dart';

void main() {
  Widget buildButton({
    required AppRepeatMode mode,
    required ValueChanged<AppRepeatMode> onChanged,
    bool showOptions = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepeatModeButton(
            mode: mode,
            showOptions: showOptions,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('compact mode cycles off to repeat one', (tester) async {
    AppRepeatMode? selected;

    await tester.pumpWidget(
      buildButton(
        mode: AppRepeatMode.off,
        showOptions: false,
        onChanged: (mode) => selected = mode,
      ),
    );

    await tester.tap(find.byIcon(Icons.repeat_outlined));
    await tester.pump();

    expect(selected, AppRepeatMode.one);
  });

  testWidgets('compact mode cycles repeat one to repeat queue', (tester) async {
    AppRepeatMode? selected;

    await tester.pumpWidget(
      buildButton(
        mode: AppRepeatMode.one,
        showOptions: false,
        onChanged: (mode) => selected = mode,
      ),
    );

    await tester.tap(find.byIcon(Icons.repeat_one));
    await tester.pump();

    expect(selected, AppRepeatMode.all);
  });

  testWidgets('compact mode cycles repeat queue to off', (tester) async {
    AppRepeatMode? selected;

    await tester.pumpWidget(
      buildButton(
        mode: AppRepeatMode.all,
        showOptions: false,
        onChanged: (mode) => selected = mode,
      ),
    );

    await tester.tap(find.byIcon(Icons.repeat));
    await tester.pump();

    expect(selected, AppRepeatMode.off);
  });

  testWidgets('options mode shows all repeat choices and selects one',
      (tester) async {
    AppRepeatMode? selected;

    await tester.pumpWidget(
      buildButton(
        mode: AppRepeatMode.one,
        onChanged: (mode) => selected = mode,
      ),
    );

    await tester.tap(find.byIcon(Icons.repeat_one));
    await tester.pumpAndSettle();

    expect(find.text("Don't repeat"), findsOneWidget);
    expect(find.text('Repeat current track'), findsOneWidget);
    expect(find.text('Repeat queue'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Repeat queue'));
    await tester.pumpAndSettle();

    expect(selected, AppRepeatMode.all);
    expect(find.text('Repeat queue'), findsNothing);
  });
}
