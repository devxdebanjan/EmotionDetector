import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/emotion_result.dart';
import '../services/camera_service.dart';
import '../services/emotion_analyzer.dart';
import '../services/image_converter.dart';
import '../painters/face_guide_painter.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  final CameraService _cameraService = CameraService();
  final EmotionAnalyzer _emotionAnalyzer = EmotionAnalyzer();

  bool _isDetecting = false;
  String _currentEmotion = "Neutral";
  double _confidenceScore = 1.0;
  String _lightingCondition = "Checking lighting...";

  double _debugSmile = 0.0;
  double _debugFrown = 0.0;
  double _debugStress = 0.0;
  double _debugTiredness = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraService.initialize(
      direction: CameraLensDirection.front,
      onFrame: (image, camera) {
        if (!_isDetecting) {
          _isDetecting = true;
          _processImage(image, camera);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _processImage(CameraImage image, CameraDescription camera) async {
    debugPrint("processing image");

    final newLight = ImageConverter.analyzeLighting(image);
    if (_lightingCondition != newLight) {
      setState(() {
        _lightingCondition = newLight;
      });
    }

    final inputImage = ImageConverter.convert(image, camera);
    if (inputImage == null) {
      debugPrint("Input image null");
      _isDetecting = false;
      return;
    }

    try {
      final faces = await _emotionAnalyzer.faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        final result = _emotionAnalyzer.analyze(faces.first);
        debugPrint("face not empty");
        setState(() {
          _currentEmotion = result.emotion;
          _confidenceScore = result.confidence;
          _debugSmile = result.smile;
          _debugFrown = result.frown;
          _debugStress = result.stress;
          _debugTiredness = result.tiredness;
        });
      } else {
        debugPrint("face empty");
        setState(() {
          _currentEmotion = EmotionResult.noFace.emotion;
          _confidenceScore = EmotionResult.noFace.confidence;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error processing face: $e");
      }
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _emotionAnalyzer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-Time Analysis', style: TextStyle(color: Theme.of(context).primaryColor)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: !_cameraService.isReady
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: _cameraService.controller!.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraService.controller!),
                          CustomPaint(
                            painter: FaceGuidePainter(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Align your face within the oval.\nKeep your head straight & parallel to the phone.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    _lightingCondition,
                    style: TextStyle(
                        fontSize: 16,
                        color: _lightingCondition.contains("Good") ? Colors.grey : Colors.redAccent,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Emotion: $_currentEmotion',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: _confidenceScore,
                    backgroundColor: Colors.grey[800],
                    color: Theme.of(context).primaryColor,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  Text(
                    'Confidence: ${(_confidenceScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEBUG SCORES', style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(
                          'Smile: ${_debugSmile.toStringAsFixed(3)}  |  Frown: ${_debugFrown.toStringAsFixed(3)}\nStress: ${_debugStress.toStringAsFixed(3)} | Tiredness: ${_debugTiredness.toStringAsFixed(3)}', 
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontFamily: 'monospace', height: 1.5),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
