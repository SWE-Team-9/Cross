import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const App());
}