import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_text_field.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Form(
          child: child,
        ),
      ),
    );
  }

  group('EditProfileTextField', () {
    testWidgets('renders label and initial controller text', (tester) async {
      final controller = TextEditingController(text: 'Ali Mahmoud');

      await tester.pumpWidget(
        wrap(
          EditProfileTextField(
            label: 'Display Name',
            controller: controller,
          ),
        ),
      );

      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Ali Mahmoud'), findsOneWidget);
    });

    testWidgets('renders multiline field and shows max length counter',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrap(
          EditProfileTextField(
            label: 'Bio',
            controller: controller,
            maxLength: 160,
            maxLines: 4,
          ),
        ),
      );

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.maxLines, 4);

      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.pump();

      expect(find.text('5/160'), findsOneWidget);
    });

    testWidgets('validator returns error text when form is validated',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController(text: 'A');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: EditProfileTextField(
                label: 'Display Name',
                controller: controller,
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('accepts text entry and updates controller', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        wrap(
          EditProfileTextField(
            label: 'City',
            controller: controller,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Cairo');
      await tester.pump();

      expect(controller.text, 'Cairo');
      expect(find.text('Cairo'), findsOneWidget);
    });
  });
}
