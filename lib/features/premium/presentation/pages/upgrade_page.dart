import 'package:flutter/material.dart';

/// Minimal placeholder for the UpgradePage so routes importing it don't break.
class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Upgrade'), SizedBox(height:8), Text('Upgrade to IQA3 Pro')],),),);
}
