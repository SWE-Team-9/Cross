import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundCloud Clone',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('SoundCloud Clone - Setup Complete'),
        ),
      ),
    );
  }
}