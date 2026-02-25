import 'dart:typed_data';

Float32List sliceOrPadTo3000(List<double> samples, {int targetLength = 3000}) {
  if (targetLength != 3000) {
    throw ArgumentError.value(
      targetLength,
      'targetLength',
      'Only 3000 is supported by the current model',
    );
  }

  final out = Float32List(targetLength);
  final n = samples.length < targetLength ? samples.length : targetLength;
  for (var i = 0; i < n; i++) {
    out[i] = samples[i].toDouble();
  }
  // Remaining values are already 0.0
  return out;
}

bool looksLikeSoftmax(List<double> probs, {double epsilon = 1e-2}) {
  final sum = probs.fold(0.0, (a, b) => a + b);
  if ((sum - 1.0).abs() > epsilon) return false;
  for (final p in probs) {
    if (p.isNaN || p.isInfinite) return false;
    if (p < -epsilon) return false;
  }

  return true;
}
