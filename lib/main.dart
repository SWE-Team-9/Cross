import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setupDependencies();

  runApp(const App());
}
