import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_pretty_logging/pro_pretty_logging.dart';

import 'ui/ecg_screen.dart';

void main() {
  prettyLogging(enable: kDebugMode);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECG Classifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const EcgScreen(),
    );
  }
}
