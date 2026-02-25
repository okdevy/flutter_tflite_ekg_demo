import 'dart:typed_data';

class EcgPrediction {
  EcgPrediction({required this.probabilities, required this.labels})
    : assert(probabilities.length == labels.length);

  final List<double> probabilities;
  final List<String> labels;

  int get argmax {
    var bestIndex = 0;
    var bestValue = probabilities.first;
    for (var i = 1; i < probabilities.length; i++) {
      final v = probabilities[i];
      if (v > bestValue) {
        bestValue = v;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  String get predictedLabel => labels[argmax];

  double get sum => probabilities.fold(0.0, (a, b) => a + b);
}

abstract class EcgClassifier {
  static const defaultLabels = <String>['Normal', 'AFib', 'Other', 'Noisy'];

  Future<EcgPrediction> classify({required Float32List signal3000});

  Future<void> close();
}
