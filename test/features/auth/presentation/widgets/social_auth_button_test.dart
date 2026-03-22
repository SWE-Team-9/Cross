import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/presentation/widgets/social_auth_button.dart';

void main() {
  group('SocialAuthButton Widget Tests', () {
    testWidgets('renders text and background color correctly', (tester) async {
      const buttonText = 'Continue with Google';
      const bgColor = Colors.white;
      const txtColor = Colors.black;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              text: buttonText,
              backgroundColor: bgColor,
              textColor: txtColor,
              onPressed: () {},
            ),
          ),
        ),
      );

      // التأكد من ظهور النص
      expect(find.text(buttonText), findsOneWidget);

      // التأكد من تطبيق اللون الخلفي على الـ ElevatedButton
      final elevatedButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.style?.backgroundColor?.resolve({}), bgColor);
    });

    testWidgets('renders leading widget (icon) when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              text: 'Facebook',
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              leading: const Icon(Icons.facebook, key: Key('social_icon')),
              onPressed: () {},
            ),
          ),
        ),
      );

      // التأكد من ظهور الأيقونة الممررة في الـ leading
      expect(find.byKey(const Key('social_icon')), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              text: 'Tap Me',
              backgroundColor: Colors.black,
              textColor: Colors.white,
              onPressed: () {
                isPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(isPressed, isTrue);
    });

    testWidgets('has correct height and full width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialAuthButton(
              text: 'Width Test',
              backgroundColor: Colors.red,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        ),
      );

      // البحث عن الـ SizedBox المحيط بالزر للتأكد من الأبعاد
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 54);
      expect(sizedBox.width, double.infinity);
    });
  });
}
