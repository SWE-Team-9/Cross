import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/unread_badge.dart';

void main() {
  group('UnreadBadge', () {
    Future<void> pumpBadge(WidgetTester tester, int count) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UnreadBadge(count: count),
            ),
          ),
        ),
      );
    }

    testWidgets('renders nothing when count is zero', (tester) async {
      await pumpBadge(tester, 0);

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders nothing when count is negative', (tester) async {
      await pumpBadge(tester, -5);

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('-5'), findsNothing);
    });

    testWidgets('renders count when count is positive', (tester) async {
      await pumpBadge(tester, 7);

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('caps large count at 99+', (tester) async {
      await pumpBadge(tester, 100);

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('renders 99 without cap', (tester) async {
      await pumpBadge(tester, 99);

      expect(find.text('99'), findsOneWidget);
      expect(find.text('99+'), findsNothing);
    });
  });
}
