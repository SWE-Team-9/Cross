import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';

void main() {
  Future<void> pumpList<T>(
    WidgetTester tester, {
    required Future<List<T>> Function(int page) fetcher,
    required Widget Function(BuildContext context, T item) itemBuilder,
    String emptyMessage = 'Nothing here yet',
    IconData emptyIcon = Icons.people_outline,
    int pageSize = 20,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: PaginatedUserList<T>(
              fetcher: fetcher,
              itemBuilder: itemBuilder,
              emptyMessage: emptyMessage,
              emptyIcon: emptyIcon,
              pageSize: pageSize,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows first-load spinner before fetch completes', (tester) async {
    final completer = Completer<List<String>>();

    await pumpList<String>(
      tester,
      fetcher: (_) => completer.future,
      itemBuilder: (_, item) => ListTile(title: Text(item)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(['A']);
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty state when first page returns no items',
      (tester) async {
    await pumpList<String>(
      tester,
      fetcher: (_) async => <String>[],
      itemBuilder: (_, item) => ListTile(title: Text(item)),
      emptyMessage: 'No followers yet',
    );

    await tester.pumpAndSettle();

    expect(find.text('No followers yet'), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
  });

  testWidgets('shows error state when first page throws', (tester) async {
    await pumpList<String>(
      tester,
      fetcher: (_) async => throw Exception('boom'),
      itemBuilder: (_, item) => ListTile(title: Text(item)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('retry button triggers a new fetch after first-load error',
      (tester) async {
    var callCount = 0;

    await pumpList<String>(
      tester,
      fetcher: (_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('boom');
        }
        return ['Recovered'];
      },
      itemBuilder: (_, item) => ListTile(title: Text(item)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Recovered'), findsOneWidget);
    expect(callCount, 2);
  });

  testWidgets('shows populated list items', (tester) async {
    await pumpList<String>(
      tester,
      fetcher: (_) async => ['One', 'Two', 'Three'],
      itemBuilder: (_, item) => ListTile(title: Text(item)),
    );

    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('loads more when scrolled near bottom', (tester) async {
    final requestedPages = <int>[];

    await pumpList<String>(
      tester,
      fetcher: (page) async {
        requestedPages.add(page);
        if (page == 1) return List.generate(20, (i) => 'Item $i');
        if (page == 2) return List.generate(20, (i) => 'More $i');
        return <String>[];
      },
      itemBuilder: (_, item) => SizedBox(
        height: 60,
        child: Text(item),
      ),
      pageSize: 20,
    );

    await tester.pumpAndSettle();

    expect(requestedPages, [1]);

    await tester.drag(find.byType(Scrollable), const Offset(0, -2000));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requestedPages, contains(2));

    await tester.scrollUntilVisible(
      find.text('More 0'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('More 0'), findsOneWidget);
  });

  testWidgets('does not load more when first page has fewer than pageSize items',
      (tester) async {
    final requestedPages = <int>[];

    await pumpList<String>(
      tester,
      fetcher: (page) async {
        requestedPages.add(page);
        return ['A', 'B'];
      },
      itemBuilder: (_, item) => SizedBox(
        height: 60,
        child: Text(item),
      ),
      pageSize: 20,
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable), const Offset(0, -1500));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);
  });

testWidgets('load-more failure keeps previously loaded data state',
    (tester) async {
  final requestedPages = <int>[];

  await pumpList<String>(
    tester,
    fetcher: (page) async {
      requestedPages.add(page);
      if (page == 1) return List.generate(20, (i) => 'Item $i');
      throw Exception('load more failed');
    },
    itemBuilder: (_, item) => SizedBox(
      height: 60,
      child: Text(item),
    ),
    pageSize: 20,
  );

  await tester.pumpAndSettle();

  expect(find.text('Item 0'), findsOneWidget);

  await tester.drag(find.byType(Scrollable), const Offset(0, -2000));
  await tester.pump();
  await tester.pumpAndSettle();

  expect(requestedPages, contains(2));

  // Existing loaded list should remain; widget should not switch to empty/error UI.
  expect(find.text('Something went wrong. Please try again.'), findsNothing);
  expect(find.text('Retry'), findsNothing);
  expect(find.text('Nothing here yet'), findsNothing);
});
}