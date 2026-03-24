import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/edit_profile_country_picker.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: child,
      ),
    );
  }

  group('EditProfileCountryPicker', () {
    testWidgets('shows Not specified when selectedCountry is empty',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileCountryPicker(
            selectedCountry: '',
            countries: const ['Egypt', 'Saudi Arabia'],
            onCountrySelected: (_) {},
          ),
        ),
      );

      expect(find.text('Country'), findsOneWidget);
      expect(find.text('Not specified'), findsOneWidget);
    });

    testWidgets('shows selected country when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileCountryPicker(
            selectedCountry: 'Egypt',
            countries: const ['Egypt', 'Saudi Arabia'],
            onCountrySelected: (_) {},
          ),
        ),
      );

      expect(find.text('Egypt'), findsOneWidget);
    });

    testWidgets('opens bottom sheet on tap', (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileCountryPicker(
            selectedCountry: '',
            countries: const ['Egypt', 'Saudi Arabia'],
            onCountrySelected: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('Select Country'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Egypt'), findsOneWidget);
      expect(find.text('Saudi Arabia'), findsOneWidget);
    });

    testWidgets('calls onCountrySelected when a country is tapped',
        (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        wrap(
          EditProfileCountryPicker(
            selectedCountry: '',
            countries: const ['Egypt', 'Saudi Arabia'],
            onCountrySelected: (value) => selectedValue = value,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saudi Arabia'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'Saudi Arabia');
      expect(find.text('Select Country'), findsNothing);
    });

    testWidgets(
        'calls onCountrySelected with empty string when Clear is tapped',
        (tester) async {
      String? selectedValue = 'Egypt';

      await tester.pumpWidget(
        wrap(
          EditProfileCountryPicker(
            selectedCountry: 'Egypt',
            countries: const ['Egypt', 'Saudi Arabia'],
            onCountrySelected: (value) => selectedValue = value,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(selectedValue, '');
      expect(find.text('Select Country'), findsNothing);
    });

    testWidgets('closes bottom sheet when Cancel is tapped', (tester) async {
      await tester.pumpWidget(
        wrap(
          EditProfileCountryPicker(
            selectedCountry: 'Egypt',
            countries: const ['Egypt', 'Saudi Arabia'],
            onCountrySelected: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('Select Country'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Select Country'), findsNothing);
    });
  });
}
