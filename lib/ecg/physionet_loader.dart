import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'hea.dart';
import 'mat_v4.dart';

class PhysioNetRecord {
  PhysioNetRecord({required this.header, required this.samples});

  final HeaRecord header;

  /// Raw samples as float values (decoded from int16 typically).
  /// Shape is [numSignals * numSamples] in row-major order.
  final Float32List samples;
}

Future<PhysioNetRecord> loadPhysioNetFromAssets({
  required String baseName,
}) async {
  final heaText = await rootBundle.loadString('assets/test/$baseName.hea');
  final header = parseHea(heaText);

  final matBytes = (await rootBundle.load(
    'assets/test/$baseName.mat',
  )).buffer.asUint8List();

  final matrix = readMatV4SingleMatrix(matBytes);
  if (matrix.name != 'val') {
    // Still proceed, but this is unexpected.
  }

  // Best-effort scaling to physical units if header provides it.
  // Many WFDB records use: physical = (adc - adcZero) / gain.
  final gain = header.gain;
  final adcZero = header.adcZero;
  if (gain != null && gain != 0 && adcZero != null) {
    for (var i = 0; i < matrix.values.length; i++) {
      matrix.values[i] = (matrix.values[i] - adcZero) / gain;
    }
  }

  return PhysioNetRecord(header: header, samples: matrix.values);
}
