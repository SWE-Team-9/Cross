import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_text_field.dart';

void main() {
  Future<void> pumpWidget(
    WidgetTester tester, {
    required TextEditingController controller,
    String label = 'Display Name',
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: EditProfileTextField(
              label: label,
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders label and initial controller value', (tester) async {
    final controller = TextEditingController(text: 'Ali');

    await pumpWidget(
      tester,
      controller: controller,
      label: 'Display Name',
    );

    expect(find.text('Display Name'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
  });

  testWidgets('updates controller text when user enters value', (tester) async {
    final controller = TextEditingController();

    await pumpWidget(tester, controller: controller);

    await tester.enterText(find.byType(TextFormField), 'New Name');
    await tester.pump();

    expect(controller.text, 'New Name');
  });

  testWidgets('renders as multiline field when maxLines is greater than 1',
      (tester) async {
    final controller = TextEditingController();

    await pumpWidget(
      tester,
      controller: controller,
      label: 'Bio',
      maxLines: 4,
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
  });

  testWidgets('shows counter when maxLength is provided', (tester) async {
    final controller = TextEditingController();

    await pumpWidget(
      tester,
      controller: controller,
      maxLength: 50,
    );

    await tester.enterText(find.byType(TextFormField), 'hello');
    await tester.pump();

    expect(find.text('5/50'), findsOneWidget);
  });

  testWidgets('shows validation error when validator fails', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            autovalidateMode: AutovalidateMode.always,
            child: EditProfileTextField(
              label: 'Display Name',
              controller: controller,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
  });
}
