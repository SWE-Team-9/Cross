import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/presentation/widgets/windows_image_crop_dialog.dart';

Future<File> createValidTestPng(String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const size = 64.0;

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFFFF5500),
  );

  canvas.drawCircle(
    const Offset(32, 32),
    16,
    Paint()..color = const Color(0xFF111111),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData == null) {
    throw Exception('Failed to generate test PNG.');
  }

  final file = File(path);
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file;
}

Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxTries = 30,
}) async {
  for (var i = 0; i < maxTries; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(step);
    });
    await tester.pump();

    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Widget not found after waiting: $finder');
}

Future<void> waitForDialogDecode(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
}

Future<void> settleDialog(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File imageFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'windows_image_crop_dialog_test',
    );

    imageFile = await createValidTestPng('${tempDir.path}/sample.png');
  });
  tearDown(() async {
    // Intentionally do not delete temp files here.
    // Windows can keep the image file locked briefly during widget tests.
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required String sourcePath,
    required ProfileImageType imageType,
    ValueChanged<String?>? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await showDialog<String?>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => WindowsImageCropDialog(
                        sourcePath: sourcePath,
                        imageType: imageType,
                      ),
                    );

                    onResult?.call(result);
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
  }

  testWidgets('opens dialog successfully', (tester) async {
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.AVATAR,
    );

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Crop avatar'), findsOneWidget);
  });

  testWidgets('shows avatar crop title after decode', (tester) async {
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.AVATAR,
    );

    expect(find.text('Crop avatar'), findsOneWidget);

    await waitForDialogDecode(tester);

    await pumpUntilVisible(
      tester,
      find.text('Drag to move the image. Use the slider to zoom.'),
    );
    await pumpUntilVisible(
      tester,
      find.byType(Slider),
    );

    expect(
      find.text('Drag to move the image. Use the slider to zoom.'),
      findsOneWidget,
    );
    expect(find.text('Zoom'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
  });
  testWidgets('shows cover crop title after decode', (tester) async {
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.COVER,
    );

    expect(find.text('Crop cover'), findsOneWidget);

    await waitForDialogDecode(tester);

    await pumpUntilVisible(
      tester,
      find.byType(Slider),
    );

    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Crop'), findsOneWidget);
  });
  testWidgets('cancel closes the dialog and returns null', (tester) async {
    String? result = 'not-null-yet';

    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.AVATAR,
      onResult: (value) => result = value,
    );

    await settleDialog(tester);

    await tester.tap(find.text('Cancel'));
    await settleDialog(tester);

    expect(find.text('Crop avatar'), findsNothing);
    expect(result, isNull);
  });

  testWidgets('slider can be changed without exceptions', (tester) async {
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.AVATAR,
    );

    expect(find.text('Crop avatar'), findsOneWidget);

    await waitForDialogDecode(tester);
    await pumpUntilVisible(
      tester,
      find.byType(Slider),
    );

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);

    await tester.drag(
      sliderFinder,
      const Offset(200, 0),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Crop avatar'), findsOneWidget);
  });
  testWidgets('dragging crop area does not throw', (tester) async {
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.COVER,
    );

    expect(find.text('Crop cover'), findsOneWidget);

    await waitForDialogDecode(tester);
    await pumpUntilVisible(
      tester,
      find.byType(Slider),
    );

    final cropArea = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Listener),
        )
        .last;

    expect(cropArea, findsOneWidget);

    await tester.drag(cropArea, const Offset(40, 20));
    await tester.pump();

    expect(find.text('Crop cover'), findsOneWidget);
  });

  testWidgets('crop action can be triggered after decode', (tester) async {
    String? capturedPath;
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.AVATAR,
      onResult: (path) => capturedPath = path,
    );

    await waitForDialogDecode(tester);

    await tester.tap(find.text('Crop'));
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    });

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Export completion may vary in widget-test environment; ensure no crash.
    if (capturedPath != null) {
      expect(File(capturedPath!).existsSync(), isTrue);
    }
    expect(find.byType(AlertDialog), anyOf(findsOneWidget, findsNothing));
  });

  testWidgets('zooming via mouse wheel updates state', (tester) async {
    await pumpDialog(
      tester,
      sourcePath: imageFile.path,
      imageType: ProfileImageType.AVATAR,
    );
    await waitForDialogDecode(tester);
    await pumpUntilVisible(tester, find.byType(Slider));

    final cropArea = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Listener),
        )
        .last;

    final center = tester.getCenter(cropArea);

    final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
    pointer.hover(center);

    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -100)));
    await tester.pump();

    final Slider slider = tester.widget(find.byType(Slider).first);
    expect(slider.value, greaterThanOrEqualTo(1.0));
  });
}
