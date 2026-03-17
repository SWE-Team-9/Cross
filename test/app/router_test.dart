import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/app/router.dart';
import 'package:soundcloud_clone/core/di/injector.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    setupDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildApp() {
    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('shows login page by default', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Login Page - Placeholder'), findsOneWidget);
  });

  testWidgets('navigates to home page', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    router.go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Home Page - Placeholder'), findsOneWidget);
  });

  testWidgets('navigates to upload picker page', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    router.go('/upload-picker');
    await tester.pumpAndSettle();

    expect(find.text('Audio File Picker'), findsOneWidget);
    expect(find.text('Select MP3 / WAV'), findsOneWidget);
  });
}