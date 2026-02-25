import 'dart:typed_data';

class MatV4Matrix {
  MatV4Matrix({
    required this.name,
    required this.rows,
    required this.cols,
    required this.values,
  });

  final String name;
  final int rows;
  final int cols;

  /// Row-major values.
  final Float32List values;
}

/// Minimal MATLAB v4 reader that supports PhysioNet-style files.
///
/// The PhysioNet AF database `.mat` records in this repo are v4 and contain a
/// single matrix named `val` of shape [numSignals, numSamples], usually int16.
MatV4Matrix readMatV4SingleMatrix(Uint8List bytes) {
  final bd = ByteData.sublistView(bytes);
  if (bd.lengthInBytes < 20) {
    throw FormatException('MAT v4 file too small');
  }

  // Header (all int32 little-endian)
  final mopt = bd.getInt32(0, Endian.little);
  final rows = bd.getInt32(4, Endian.little);
  final cols = bd.getInt32(8, Endian.little);
  final imagf = bd.getInt32(12, Endian.little);
  final nameLen = bd.getInt32(16, Endian.little);

  if (rows <= 0 || cols <= 0) {
    throw FormatException('Invalid matrix shape: $rows x $cols');
  }
  if (imagf != 0) {
    throw FormatException('Complex matrices are not supported');
  }
  if (nameLen <= 0 || 20 + nameLen > bd.lengthInBytes) {
    throw FormatException('Invalid name length: $nameLen');
  }

  final nameBytes = bytes.sublist(20, 20 + nameLen);
  final zeroIndex = nameBytes.indexOf(0);
  final actualNameBytes = zeroIndex == -1
      ? nameBytes
      : nameBytes.sublist(0, zeroIndex);
  final name = String.fromCharCodes(actualNameBytes);

  final dataOffset = 20 + nameLen;
  final count = rows * cols;
  final dataBytes = bd.lengthInBytes - dataOffset;
  if (dataBytes <= 0) {
    throw FormatException('No matrix data');
  }

  // Infer element width from remaining bytes.
  final bytesPerElement = dataBytes ~/ count;
  if (bytesPerElement * count != dataBytes) {
    // Some files may include padding; try to tolerate by truncating.
    final usable = bytesPerElement * count;
    if (usable <= 0 || usable > dataBytes) {
      throw FormatException('Unexpected MAT v4 data layout');
    }
  }

  final values = Float32List(count);

  // Interpret numeric payload (PhysioNet uses int16 for ECG signals).
  // We do best-effort decoding based on inferred byte width.
  switch (bytesPerElement) {
    case 2:
      for (var i = 0; i < count; i++) {
        final v = bd.getInt16(dataOffset + i * 2, Endian.little);
        values[i] = v.toDouble();
      }
      break;
    case 4:
      // Could be float32 or int32; try float32 by default.
      for (var i = 0; i < count; i++) {
        values[i] = bd.getFloat32(dataOffset + i * 4, Endian.little);
      }
      break;
    case 8:
      for (var i = 0; i < count; i++) {
        values[i] = bd.getFloat64(dataOffset + i * 8, Endian.little).toDouble();
      }
      break;
    default:
      throw FormatException(
        'Unsupported element size: $bytesPerElement (mopt=$mopt)',
      );
  }

  return MatV4Matrix(name: name, rows: rows, cols: cols, values: values);
}
