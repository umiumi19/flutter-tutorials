import 'package:flutter/material.dart';
import '../../config.dart';

class DartDefinePage extends StatelessWidget {
  const DartDefinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('02. dart-define')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ENV = ${AppConfig.env}'),
            Text('API = ${AppConfig.apiBase}'),
          ],
        ),
      ),
    );
  }
}
