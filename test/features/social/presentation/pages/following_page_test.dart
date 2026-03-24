import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/following_page.dart';

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(
      home: FollowingPage(handle: 'ali'),
    );
  }

  group('FollowingPage', () {
    testWidgets('renders app bar title and empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Not following anyone yet'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
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
      const page = FollowingPage(handle: 'ali');

      expect(page.handle, 'ali');
    });
  });
}
