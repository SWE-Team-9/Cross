import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/presentation/widgets/auth_screen_wrapper.dart';

void main() {
  group('AuthScreenWrapper', () {
    testWidgets('renders child inside scaffold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreenWrapper(
            child: Text('Wrapped Child'),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Wrapped Child'), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('uses expected background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreenWrapper(
            child: SizedBox(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0B0B0B));
    });
  });
}
