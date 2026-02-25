import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_demo/ecg/hea.dart';
import 'package:tflite_demo/ecg/physionet_loader.dart';
import 'package:tflite_demo/inference/ecg_classifier.dart';
import 'package:tflite_demo/ui/ecg_screen.dart';

class FakeClassifier implements EcgClassifier {
  FakeClassifier({required this.result});

  final EcgPrediction result;
  int calls = 0;

  @override
  Future<EcgPrediction> classify({required Float32List signal3000}) async {
    calls++;
    expect(signal3000.length, 3000);
    return result;
  }

  @override
  Future<void> close() async {}
}

class ThrowingClassifier implements EcgClassifier {
  @override
  Future<EcgPrediction> classify({required Float32List signal3000}) async {
    throw StateError('boom');
  }

  @override
  Future<void> close() async {}
}

PhysioNetRecord fakeRecord({int totalSamples = 9000}) {
  final header = HeaRecord(
    recordName: 'A00001',
    numSignals: 1,
    sampleRateHz: 300,
    numSamples: totalSamples,
    gain: 1000,
    adcZero: -127,
  );
  final samples = Float32List.fromList(
    List<double>.generate(totalSamples, (i) => i.toDouble()),
  );
  return PhysioNetRecord(header: header, samples: samples);
}

void main() {
  testWidgets('loads bundled record and shows prediction', (tester) async {
    final classifier = FakeClassifier(
      result: EcgPrediction(
        probabilities: const [0.1, 0.7, 0.1, 0.1],
        labels: EcgClassifier.defaultLabels,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EcgScreen(
          classifier: classifier,
          loadBundledRecord: () async => fakeRecord(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Model loaded'), findsOneWidget);

    await tester.tap(find.text('Use bundled sample'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Record:'), findsOneWidget);

    await tester.tap(find.text('Classify'));
    await tester.pumpAndSettle();

    expect(find.text('Prediction: AFib'), findsOneWidget);
    expect(find.textContaining('Normal:'), findsOneWidget);
    expect(find.textContaining('AFib:'), findsOneWidget);

    expect(classifier.calls, 1);
  });

  testWidgets('shows error when classifier throws', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EcgScreen(
          classifier: ThrowingClassifier(),
          loadBundledRecord: () async => fakeRecord(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Use bundled sample'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classify'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Inference failed:'), findsOneWidget);
  });
}
