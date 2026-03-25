import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_country_picker.dart';

void main() {
  Future<void> pumpWidget(
    WidgetTester tester, {
    required String selectedCountry,
    required List<String> countries,
    required ValueChanged<String> onCountrySelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditProfileCountryPicker(
            selectedCountry: selectedCountry,
            countries: countries,
            onCountrySelected: onCountrySelected,
          ),
        ),
      ),
    );
  }

  testWidgets('shows selected country', (tester) async {
    await pumpWidget(
      tester,
      selectedCountry: 'Egypt',
      countries: const ['Egypt', 'Germany'],
      onCountrySelected: (_) {},
    );

    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Egypt'), findsOneWidget);
  });

  testWidgets('shows Not specified when selectedCountry is empty',
      (tester) async {
    await pumpWidget(
      tester,
      selectedCountry: '',
      countries: const ['Egypt', 'Germany'],
      onCountrySelected: (_) {},
    );

    expect(find.text('Not specified'), findsOneWidget);
  });

  testWidgets('opens bottom sheet when tapped', (tester) async {
    await pumpWidget(
      tester,
      selectedCountry: '',
      countries: const ['Egypt', 'Germany'],
      onCountrySelected: (_) {},
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.text('Select Country'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Egypt'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
  });

  testWidgets('selecting a country triggers callback and closes sheet',
      (tester) async {
    String? selected;

    await pumpWidget(
      tester,
      selectedCountry: '',
      countries: const ['Egypt', 'Germany'],
      onCountrySelected: (value) => selected = value,
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Germany'));
    await tester.pumpAndSettle();

    expect(selected, 'Germany');
    expect(find.text('Select Country'), findsNothing);
  });

  testWidgets('clear triggers empty selection and closes sheet',
      (tester) async {
    String? selected = 'Egypt';

    await pumpWidget(
      tester,
      selectedCountry: 'Egypt',
      countries: const ['Egypt', 'Germany'],
      onCountrySelected: (value) => selected = value,
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(selected, '');
    expect(find.text('Select Country'), findsNothing);
  });

  testWidgets('cancel closes sheet without changing selection', (tester) async {
    String? selected = 'Egypt';

    await pumpWidget(
      tester,
      selectedCountry: 'Egypt',
      countries: const ['Egypt', 'Germany'],
      onCountrySelected: (value) => selected = value,
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(selected, 'Egypt');
    expect(find.text('Select Country'), findsNothing);
  });
}