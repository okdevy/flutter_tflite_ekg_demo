# tflite_demo

Flutter demo app for **on-device ECG rhythm classification** using **TensorFlow
Lite** via `tflite_flutter`.

The UI lets you load a PhysioNet/WFDB-style record (`.mat` + matching `.hea`),
preprocess it to the model’s expected length (3000 samples), run inference, and
display per-class probabilities.

## What it does

- Runs a bundled TFLite model from `assets/models/` on-device (no server calls).
- Loads ECG samples from:
  - a bundled sample record in `assets/test/` (A00001), or
  - a user-picked `.mat` file with a `.hea` file next to it.
- Best-effort scales samples to physical units using `gain` / `adcZero` values
  from the `.hea` header.
- Classifies into 4 labels (default): `Normal`, `AFib`, `Other`, `Noisy`.

## Quick start

```bash
flutter pub get
flutter run
```

In the app:

- Tap **Use bundled sample** (A00001), then **Classify**.
- Or tap **Pick .mat** and select a record; the app expects the matching `.hea`
  alongside it.

## Project structure

- `lib/ui/` — simple screen to load data and show results
- `lib/ecg/` — PhysioNet/WFDB parsing (`.hea`) + MATLAB v4 `.mat` decoding
- `lib/inference/` — classifier interface + TFLite interpreter wrapper
- `assets/models/` — bundled `.tflite` model
- `assets/test/` — bundled sample record used by tests and the app

## Notes

- The current model expects input shaped like `(1, 3000, 1)`.
- The app slices/pads signals to 3000 samples (no resampling).
