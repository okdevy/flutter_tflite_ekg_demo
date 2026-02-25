class HeaRecord {
  HeaRecord({
    required this.recordName,
    required this.numSignals,
    required this.sampleRateHz,
    required this.numSamples,
    this.gain,
    this.adcZero,
  });

  final String recordName;
  final int numSignals;
  final int sampleRateHz;
  final int numSamples;

  // Optional signal scaling info (best-effort parse).
  final double? gain;
  final int? adcZero;
}

HeaRecord parseHea(String heaContents) {
  final lines = heaContents
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty) {
    throw FormatException('Empty .hea file');
  }

  final headerParts = lines.first.split(RegExp(r'\s+'));
  if (headerParts.length < 4) {
    throw FormatException('Invalid .hea header line: ${lines.first}');
  }

  final recordName = headerParts[0];
  final numSignals = int.parse(headerParts[1]);
  final sampleRateHz = int.parse(headerParts[2]);
  final numSamples = int.parse(headerParts[3]);

  double? gain;
  int? adcZero;

  // Best-effort parse of the first signal line (PhysioNet typically has one).
  if (lines.length >= 2) {
    final sigParts = lines[1].split(RegExp(r'\s+'));
    // Example: A00001.mat 16+24 1000/mV 16 0 -127 0 0 ECG
    if (sigParts.length >= 3) {
      final gainUnit = sigParts[2];
      final gainStr = gainUnit.split('/').first;
      final parsed = double.tryParse(gainStr);
      if (parsed != null) gain = parsed;
    }

    // Try to find an adcZero-like field (commonly near the middle).
    // This file has -127 which is very likely the ADC zero.
    for (final p in sigParts) {
      final v = int.tryParse(p);
      if (v == null) continue;
      if (v < 0) {
        adcZero = v;
        break;
      }
    }
  }

  return HeaRecord(
    recordName: recordName,
    numSignals: numSignals,
    sampleRateHz: sampleRateHz,
    numSamples: numSamples,
    gain: gain,
    adcZero: adcZero,
  );
}
