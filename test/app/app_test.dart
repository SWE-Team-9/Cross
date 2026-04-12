import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/app/app.dart';

void main() {
  group('App Widget - isTrackSheetOpen', () {
    testWidgets('isTrackSheetOpen is initialized to false', (tester) async {
      expect(isTrackSheetOpen.value, isFalse);
    });

    testWidgets('can toggle track sheet visibility',
        (WidgetTester tester) async {
      final initialValue = isTrackSheetOpen.value;

      isTrackSheetOpen.value = !initialValue;
      expect(isTrackSheetOpen.value, !initialValue);

      isTrackSheetOpen.value = initialValue;
      expect(isTrackSheetOpen.value, initialValue);
    });
  });
}
