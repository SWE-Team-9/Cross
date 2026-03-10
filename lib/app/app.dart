import 'package:flutter/material.dart';
import 'router.dart';
import '../core/di/injector.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    setupDependencies();

    return MaterialApp.router(
      title: 'SoundCloud Clone',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
