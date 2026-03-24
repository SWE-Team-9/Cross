import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/followers_page.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: FollowersPage(handle: 'ali'),
    );
  }

  group('FollowersPage', () {
    testWidgets('renders app bar title and empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('No followers yet'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('uses black scaffold background', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('contains PaginatedUserList<String>', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(PaginatedUserList<String>), findsOneWidget);
    });

    testWidgets('stores provided handle', (tester) async {
      const page = FollowersPage(handle: 'ali');

      expect(page.handle, 'ali');
    });
  });
}
