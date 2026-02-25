import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tflite_demo/inference/tflite_ecg_classifier.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('runs model inference (sanity)', (tester) async {
    final classifier = await TfliteEcgClassifier.create();

    try {
      final signal = Float32List(3000);
      final pred = await classifier.classify(signal3000: signal);

      expect(pred.probabilities.length, 4);
      for (final v in pred.probabilities) {
        expect(v.isNaN, isFalse);
        expect(v.isInfinite, isFalse);
      }

      final best = pred.argmax;
      expect(best >= 0 && best < 4, isTrue);
    } finally {
      await classifier.close();
    }
  });
}
