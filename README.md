# Emotion Detector

A Flutter mobile app that uses the front camera to detect a face in real time, estimate a simple emotion label, and show a live confidence bar.

## What this project uses

- Flutter (Dart)
- `camera` for live camera stream
- `google_mlkit_face_detection` for on-device face detection/classification
- `permission_handler` for runtime camera permission

## How it works

1. The app starts on `HomePage` and asks for camera permission.
2. `DetectionPage` opens the front camera and starts an image stream.
3. Each frame is converted to an `InputImage` for ML Kit.
4. ML Kit returns face data (smile + eye-open probabilities).
5. A lightweight rule-based mapper converts those probabilities into labels like `Happy`, `Tired`, `Stressed`, `Sad`, or `Neutral`.
6. The UI updates with:
- Current lighting quality (basic luminance check)
- Current emotion label
- Confidence progress indicator

## Run locally

Prerequisites:

- Flutter SDK installed (`flutter --version`)
- Android Studio/Xcode setup for mobile targets
- A physical device recommended for camera testing

Commands:

```bash
flutter pub get
flutter run
```

## How to test

1. Launch the app on Android/iOS device.
2. Tap **Start Detection**.
3. Grant camera permission.
4. Verify camera preview appears.
5. Move between dark and bright areas and confirm lighting message changes.
6. Change expression (smile / neutral / tired eyes) and confirm emotion + confidence update.

## Future Improvements

- A Switching Option between front and back camera
- Improvements in UI