import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/emotion_result.dart';

class EmotionAnalyzer {    // analyzes the facial experssions and outputs the emotions
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: false,
      enableContours: true,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  EmotionResult analyze(Face face) {
    final smile = face.smilingProbability ?? 0.0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.5;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.5;

    final frownScore = _detectFrown(face);
    final stressScore = _detectEyebrowRaise(face) * 0.7 + ((leftEyeOpen + rightEyeOpen) / 2.0) * 0.3;
    final tirednessScore = _detectTiredness(smile, leftEyeOpen, rightEyeOpen);

    String emotion = "Neutral";
    double confidence = 0.5;

    if (smile > 0.85) {
      emotion = "Happy";
      confidence = smile;
    }
    else if (frownScore > 0.3) {
      emotion = "Sad";
      confidence = frownScore.clamp(0.0, 1.0);
    }
    else if (stressScore > 0.78 && smile < 0.3) {
      emotion = "Stressed";
      confidence = stressScore.clamp(0.0, 1.0);
    }
    else if (tirednessScore > 0.55) {
      emotion = "Tired";
      confidence = tirednessScore.clamp(0.0, 1.0);
    }

    return EmotionResult(
      emotion: emotion,
      confidence: confidence,
      smile: smile,
      frown: frownScore,
      stress: stressScore,
      tiredness: tirednessScore,
    );
  }

  double _detectFrown(Face face) {
    final faceContour = face.contours[FaceContourType.face];
    final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];
    final noseBottom = face.contours[FaceContourType.noseBottom];

    if (faceContour == null || faceContour.points.length < 10 ||
        lowerLipBottom == null || lowerLipBottom.points.isEmpty ||
        noseBottom == null || noseBottom.points.isEmpty) {
      return 0.0;
    }

    double chinY = faceContour.points.first.y.toDouble();
    for (final p in faceContour.points) {
      if (p.y > chinY) chinY = p.y.toDouble();
    }

    final lowerLipCenterY = lowerLipBottom.points[lowerLipBottom.points.length ~/ 2].y.toDouble();
    final noseBottomCenterY = noseBottom.points[noseBottom.points.length ~/ 2].y.toDouble();
    final chinToLip = (chinY - lowerLipCenterY).abs();
    final lipToNose = (lowerLipCenterY - noseBottomCenterY).abs();
    if (lipToNose < 1.0) return 0.0;
    final ratio = chinToLip / lipToNose;
    final frownScore = (ratio - 1.0) * 2.5;

    return frownScore.clamp(0.0, 1.5);
  }

  double _detectEyebrowRaise(Face face) {
    final leftEyebrow = face.contours[FaceContourType.leftEyebrowTop];
    final rightEyebrow = face.contours[FaceContourType.rightEyebrowTop];
    final leftEye = face.contours[FaceContourType.leftEye];
    final rightEye = face.contours[FaceContourType.rightEye];
    final noseBridge = face.contours[FaceContourType.noseBridge];

    if (leftEyebrow == null || rightEyebrow == null ||
        leftEye == null || rightEye == null ||
        noseBridge == null || noseBridge.points.length < 2) {
      return 0.0;
    }

    final leftBrowCenterY = leftEyebrow.points[leftEyebrow.points.length ~/ 2].y.toDouble();
    final rightBrowCenterY = rightEyebrow.points[rightEyebrow.points.length ~/ 2].y.toDouble();
    final avgBrowY = (leftBrowCenterY + rightBrowCenterY) / 2.0;

    final leftEyeCenterY = leftEye.points[leftEye.points.length ~/ 2].y.toDouble();
    final rightEyeCenterY = rightEye.points[rightEye.points.length ~/ 2].y.toDouble();
    final avgEyeY = (leftEyeCenterY + rightEyeCenterY) / 2.0;

    final noseTop = noseBridge.points.first;
    final noseBottom = noseBridge.points.last;
    final noseBridgeLength = (noseBottom.y - noseTop.y).abs().toDouble();
    if (noseBridgeLength < 1.0) return 0.0;

    final browToEyeDistance = (avgEyeY - avgBrowY) / noseBridgeLength;
    final raiseScore = (browToEyeDistance - 0.4) * 2.5;

    return raiseScore.clamp(0.0, 1.0);
  }

  double _detectTiredness(double smile, double leftEyeOpen, double rightEyeOpen) {
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2.0;
    return (1.0 - avgEyeOpen);
  }
  
  void dispose() {
    faceDetector.close();
  }
}
