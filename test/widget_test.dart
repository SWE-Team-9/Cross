import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/app/app.dart';

void main() {
  testWidgets('App shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Login Page - Placeholder'), findsOneWidget);
  });
}