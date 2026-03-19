import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('PaginatedUserList', () {
    testWidgets('shows spinner on first load', (tester) async {
      final widget = PaginatedUserList<String>(
        fetcher: (_) async {
          // Use a shorter delay that we can actually wait for
          await Future.delayed(const Duration(milliseconds: 100));
          return [];
        },
        itemBuilder: (_, item) => Text(item),
      );

      await tester.pumpWidget(wrap(widget));
      
      // Verify spinner is shown immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for the Future to complete
      await tester.pump(const Duration(milliseconds: 100));
      
      // Allow the widget to rebuild after Future completes
      await tester.pump();
      
      // No more spinner
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders items returned by fetcher', (tester) async {
      final widget = PaginatedUserList<String>(
        fetcher: (_) async => ['Alice', 'Bob', 'Charlie'],
        itemBuilder: (_, item) => ListTile(title: Text(item)),
      );

      await tester.pumpWidget(wrap(widget));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('shows empty state when fetcher returns empty list',
        (tester) async {
      const msg = 'No followers yet';
      final widget = PaginatedUserList<String>(
        fetcher: (_) async => [],
        itemBuilder: (_, item) => Text(item),
        emptyMessage: msg,
      );

      await tester.pumpWidget(wrap(widget));
      
      // Wait for the initial load to complete
      await tester.pumpAndSettle();

      expect(find.text(msg), findsOneWidget);
    });

    testWidgets('shows error state with retry button on exception',
        (tester) async {
      final widget = PaginatedUserList<String>(
        fetcher: (_) async => throw Exception('Network error'),
        itemBuilder: (_, item) => Text(item),
      );

      await tester.pumpWidget(wrap(widget));
      
      // Wait for the error to be processed
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button reloads the list', (tester) async {
      int calls = 0;
      final widget = PaginatedUserList<String>(
        fetcher: (_) async {
          calls++;
          if (calls == 1) throw Exception('First call fails');
          return ['Item after retry'];
        },
        itemBuilder: (_, item) => ListTile(title: Text(item)),
      );

      await tester.pumpWidget(wrap(widget));
      await tester.pumpAndSettle(); // Wait for error state

      // Error state is showing — tap retry
      await tester.tap(find.text('Retry'));
      await tester.pump(); // Start the retry
      await tester.pumpAndSettle(); // Wait for completion

      expect(find.text('Item after retry'), findsOneWidget);
    });

    testWidgets('pull-to-refresh calls fetcher again', (tester) async {
      int calls = 0;
      final widget = PaginatedUserList<String>(
        fetcher: (_) async {
          calls++;
          return ['Item $calls'];
        },
        itemBuilder: (_, item) => ListTile(title: Text(item)),
      );

      await tester.pumpWidget(wrap(widget));
      await tester.pumpAndSettle();
      expect(calls, 1);

      // Perform pull-to-refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump(); // Start refresh
      await tester.pumpAndSettle(); // Wait for completion

      expect(calls, 2);
    });

    testWidgets('no load-more spinner when list is smaller than pageSize',
        (tester) async {
      final widget = PaginatedUserList<String>(
        fetcher: (_) async => ['OnlyOne'],
        itemBuilder: (_, item) => ListTile(title: Text(item)),
        pageSize: 20,
      );

      await tester.pumpWidget(wrap(widget));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}