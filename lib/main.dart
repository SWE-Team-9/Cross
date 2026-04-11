import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injector.dart';
import 'core/deep_links/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  await getIt<DeepLinkService>()
      .init(); // ADD — boots cold + warm link listener

  runApp(const App());
}
