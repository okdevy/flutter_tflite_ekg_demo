import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_demo/ecg/preprocess.dart';

void main() {
  group('sliceOrPadTo3000', () {
    test('pads shorter input with zeros', () {
      final out = sliceOrPadTo3000(<double>[1, 2, 3]);
      expect(out.length, 3000);
      expect(out[0], 1);
      expect(out[1], 2);
      expect(out[2], 3);
      expect(out[3], 0);
      expect(out[2999], 0);
    });

    test('truncates longer input', () {
      final samples = List<double>.generate(9000, (i) => i.toDouble());
      final out = sliceOrPadTo3000(samples);
      expect(out.length, 3000);
      expect(out[0], 0);
      expect(out[1], 1);
      expect(out[2999], 2999);
    });

    test('accepts Float32List input', () {
      final samples = Float32List.fromList(List<double>.filled(9000, 5.0));
      final out = sliceOrPadTo3000(samples);
      expect(out.length, 3000);
      expect(out.every((e) => e == 5.0), true);
    });
  });

  group('looksLikeSoftmax', () {
    test('true for a valid probability distribution', () {
      expect(looksLikeSoftmax(<double>[0.1, 0.2, 0.3, 0.4]), true);
    });

    test('false when sum is not ~1', () {
      expect(looksLikeSoftmax(<double>[1, 1, 1, 1]), false);
    });

    test('false when contains NaN/Infinity', () {
      expect(looksLikeSoftmax(<double>[0.25, double.nan, 0.25, 0.5]), false);
      expect(
        looksLikeSoftmax(<double>[0.25, double.infinity, 0.25, 0.5]),
        false,
      );
    });
  });
}
