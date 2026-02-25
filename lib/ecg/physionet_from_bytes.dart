import 'dart:typed_data';

import 'hea.dart';
import 'mat_v4.dart';
import 'physionet_loader.dart';

Future<PhysioNetRecord> loadPhysioNetFromBytes({
  required Uint8List matBytes,
  required String heaText,
}) async {
  final header = parseHea(heaText);
  final matrix = readMatV4SingleMatrix(matBytes);

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
