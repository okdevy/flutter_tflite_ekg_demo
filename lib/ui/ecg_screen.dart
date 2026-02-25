import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../ecg/physionet_from_bytes.dart';
import '../ecg/physionet_loader.dart';
import '../ecg/preprocess.dart';
import '../inference/ecg_classifier.dart';
import '../inference/tflite_ecg_classifier.dart';

class EcgScreen extends StatefulWidget {
  const EcgScreen({super.key, this.classifier, this.loadBundledRecord});

  final EcgClassifier? classifier;
  final Future<PhysioNetRecord> Function()? loadBundledRecord;

  @override
  State<EcgScreen> createState() => _EcgScreenState();
}

class _EcgScreenState extends State<EcgScreen> {
  EcgClassifier? _classifier;
  bool _loadingModel = true;
  bool _busy = false;

  String? _loadedRecordName;
  PhysioNetRecord? _record;
  EcgPrediction? _prediction;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initClassifier();
  }

  Future<void> _initClassifier() async {
    try {
      if (widget.classifier != null) {
        _classifier = widget.classifier;
      } else {
        _classifier = await TfliteEcgClassifier.create();
      }
    } catch (e) {
      _error = 'Failed to load model: $e';
    } finally {
      if (mounted) {
        setState(() {
          _loadingModel = false;
        });
      }
    }
  }

  @override
  void dispose() {
    final owned = widget.classifier == null;
    if (owned) {
      _classifier?.close();
    }
    super.dispose();
  }

  Future<void> _loadBundledSample() async {
    setState(() {
      _busy = true;
      _error = null;
      _prediction = null;
    });

    try {
      final loader =
          widget.loadBundledRecord ??
          () => loadPhysioNetFromAssets(baseName: 'A00001');
      final record = await loader();
      setState(() {
        _record = record;
        _loadedRecordName = 'A00001 (bundled)';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bundled sample: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _pickMatFile() async {
    setState(() {
      _busy = true;
      _error = null;
      _prediction = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mat'],
      );
      if (result == null) {
        return;
      }
      final picked = result.files.single;
      final matPath = picked.path;
      if (matPath == null) {
        throw StateError('No file path returned by picker');
      }

      final heaPath = matPath.replaceAll(
        RegExp(r'\.mat$', caseSensitive: false),
        '.hea',
      );
      final heaFile = File(heaPath);
      if (!await heaFile.exists()) {
        throw StateError(
          'Missing .hea next to selected .mat. Expected: $heaPath',
        );
      }

      final matBytes = await File(matPath).readAsBytes();
      final heaText = await heaFile.readAsString();

      final record = await loadPhysioNetFromBytes(
        matBytes: matBytes,
        heaText: heaText,
      );

      setState(() {
        _record = record;
        _loadedRecordName = picked.name;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load file: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _classify() async {
    final classifier = _classifier;
    final record = _record;
    if (classifier == null || record == null) return;

    setState(() {
      _busy = true;
      _error = null;
      _prediction = null;
    });

    try {
      final signal3000 = sliceOrPadTo3000(record.samples);
      final pred = await classifier.classify(signal3000: signal3000);
      setState(() {
        _prediction = pred;
      });
    } catch (e) {
      setState(() {
        _error = 'Inference failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelStatus = _loadingModel
        ? 'Loading model…'
        : (_classifier == null ? 'Model error' : 'Model loaded');

    return Scaffold(
      appBar: AppBar(title: const Text('ECG classification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(modelStatus),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_busy || _loadingModel)
                        ? null
                        : _loadBundledSample,
                    child: const Text('Use bundled sample'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_busy || _loadingModel) ? null : _pickMatFile,
                    child: const Text('Pick .mat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (_busy || _loadingModel || _record == null)
                  ? null
                  : _classify,
              child: const Text('Classify'),
            ),
            const SizedBox(height: 12),
            if (_loadedRecordName != null) Text('Record: $_loadedRecordName'),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_prediction != null) ...[
              const SizedBox(height: 12),
              _PredictionCard(prediction: _prediction!),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.prediction});

  final EcgPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final softmaxLike = looksLikeSoftmax(prediction.probabilities);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction: ${prediction.predictedLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < prediction.labels.length; i++)
              Text('${prediction.labels[i]}: ${prediction.probabilities[i]}'),
            const SizedBox(height: 8),
            Text(
              'Sum: ${prediction.sum} (${softmaxLike ? 'softmax-like' : 'not softmax'})',
            ),
          ],
        ),
      ),
    );
  }
}
