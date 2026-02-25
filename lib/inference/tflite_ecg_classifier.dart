import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'ecg_classifier.dart';

class TfliteEcgClassifier implements EcgClassifier {
  TfliteEcgClassifier._({
    required Interpreter interpreter,
    required List<String> labels,
  }) : _interpreter = interpreter,
       _labels = labels;

  final Interpreter _interpreter;
  final List<String> _labels;

  static const _modelAssetPath = 'assets/models/model5_accuracy_0.9357.tflite';

  static Future<TfliteEcgClassifier> create({List<String>? labels}) async {
    final options = InterpreterOptions();

    // Start CPU-first for determinism. Delegates can be added later if needed.
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    final interpreter = await Interpreter.fromAsset(
      _modelAssetPath,
      options: options,
    );

    // Helpful debug info to confirm tensor contract.
    final input = interpreter.getInputTensors().first;
    final output = interpreter.getOutputTensors().first;
    debugPrint('TFLite input: shape=${input.shape} type=${input.type}');
    debugPrint('TFLite output: shape=${output.shape} type=${output.type}');

    return TfliteEcgClassifier._(
      interpreter: interpreter,
      labels: labels ?? EcgClassifier.defaultLabels,
    );
  }

  @override
  Future<EcgPrediction> classify({required Float32List signal3000}) async {
    if (signal3000.length != 3000) {
      throw ArgumentError.value(
        signal3000.length,
        'signal3000.length',
        'Must be exactly 3000',
      );
    }

    final input = _reshapeToInput(signal3000);
    final output = List<double>.filled(4, 0).reshape([1, 4]);

    _interpreter.run(input, output);

    return EcgPrediction(
      probabilities: List<double>.from(output[0]),
      labels: _labels,
    );
  }

  List<List<List<double>>> _reshapeToInput(Float32List signal) {
    // Model conversion script uses input shape: (1, 3000, 1)
    // tflite_flutter wants nested Lists.
    final rows = List<List<double>>.generate(
      3000,
      (i) => <double>[signal[i]],
      growable: false,
    );

    return <List<List<double>>>[rows];
  }

  @override
  Future<void> close() async {
    _interpreter.close();
  }
}
