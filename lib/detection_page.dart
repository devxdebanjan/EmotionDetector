import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: false,
      enableContours: false,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isDetecting = false;
  String _currentEmotion = "Neutral";
  double _confidenceScore = 1.0;
  String _lightingCondition = "Checking lighting...";
  
  final CameraLensDirection _cameraDirection = CameraLensDirection.front;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == _cameraDirection,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );


    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});

      _cameraController!.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _processImage(image, frontCamera);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error initializing camera: $e");
      }
    }
  }

  void _analyzeLighting(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      final Uint8List yPlane = image.planes[0].bytes;
      int totalLuma = 0;
      // Sampling every 10th pixel
      for (int i = 0; i < yPlane.length; i += 10) {
        totalLuma += yPlane[i];
      }

      final double avgLuma = totalLuma / (yPlane.length / 10);
      
      String newLight = "Good Lighting";
      if (avgLuma < 50) {
        newLight = "Too Dim! Move to brighter lighting.";
      } else if (avgLuma > 200) {
        newLight = "Too Bright! Lower the lighting.";
      }
      
      if (_lightingCondition != newLight) {
        setState(() {
          _lightingCondition = newLight;
        });
      }
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      // Analyze BGRA for luminance
      final Uint8List bytes = image.planes[0].bytes;
      int totalLuma = 0;
      for (int i = 0; i < bytes.length; i += 40) { // Sampling every 10th pixel (4 bytes/pixel)
        // Luma formula approx: 0.299*R + 0.587*G + 0.114*B
        totalLuma += (0.114 * bytes[i] + 0.587 * bytes[i+1] + 0.299 * bytes[i+2]).toInt();
      }
      final double avgLuma = totalLuma / (bytes.length / 40);
      
      String newLight = "Good Lighting";
      if (avgLuma < 50) {
        newLight = "Too Dim! Move to brighter lighting.";
      } else if (avgLuma > 200) {
        newLight = "Too Bright! Lower the lighting.";
      }
      
      if (_lightingCondition != newLight) {
        setState(() {
          _lightingCondition = newLight;
        });
      }
    }
  }

  Future<void> _processImage(CameraImage image, CameraDescription camera) async {
    debugPrint("processing image");
    _analyzeLighting(image);

    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null) {
      debugPrint("Input image null");
      _isDetecting = false;
      return;
    }

    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        final face = faces.first; 
        _analyzeEmotion(face);
        debugPrint("face not empty");
      } else {
        debugPrint("face empty");
        setState(() {
          _currentEmotion = "No face detected";
          _confidenceScore = 0.0;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error processing face: $e");
      }
    }

    // Freeing up flag after a small delay to limit frame processing rate
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _isDetecting = false;
    }
  }

  void _analyzeEmotion(Face face) {
    if (face.smilingProbability != null && face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      final smile = face.smilingProbability!;
      final eyesOpen = (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2.0;
      
      String emotion = "Neutral";
      double confidence = 0.0;
      
      if (smile > 0.8) {
        emotion = "Happy";
        confidence = smile;
      } else if (eyesOpen < 0.4 && smile < 0.1) {
        emotion = "Tired";
        confidence = 1.0 - eyesOpen;
      } else if (eyesOpen > 0.99 && smile < 0.1) {
        emotion = "Stressed";
        confidence = eyesOpen;
      } else if (smile < 0.1 && eyesOpen > 0.4 && eyesOpen < 0.99) {
        emotion = "Sad";
        confidence = 1.0 - smile;
      } else {
        emotion = "Neutral";
        confidence = 0.5;
      }

      setState(() {
        _currentEmotion = emotion;
        _confidenceScore = confidence;
      });
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
  final rotations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final sensorOrientation = camera.sensorOrientation;
  InputImageRotation? rotation;

  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    var rotationCompensation = rotations[DeviceOrientation.portraitUp];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  if (rotation == null || image.planes.isEmpty) return null;

  Uint8List bytes;
  InputImageFormat format;
  int bytesPerRow;

  if (Platform.isAndroid) {
    if (image.format.group == ImageFormatGroup.nv21) {
      bytes = image.planes.first.bytes;
      format = InputImageFormat.nv21;
      bytesPerRow = image.planes.first.bytesPerRow;
    } else if (image.format.group == ImageFormatGroup.yuv420 && image.planes.length == 3) {
      bytes = _yuv420ToNv21(image); // converting yuv420 to nv21
      format = InputImageFormat.nv21;
      bytesPerRow = image.width;
    } else {
      debugPrint('Unsupported Android format raw=${image.format.raw}, group=${image.format.group}');
      return null;
    }
  } else if (Platform.isIOS) {
    final iosFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (iosFormat != InputImageFormat.bgra8888) return null;
    bytes = image.planes.first.bytes;
    format = InputImageFormat.bgra8888;
    bytesPerRow = image.planes.first.bytesPerRow;
  } else {
    return null;
  }

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: bytesPerRow,
      ),
    );
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + (width * height ~/ 2));
    var offset = 0;

    for (int row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      nv21.setRange(offset, offset + width, yPlane.bytes, rowStart);
      offset += width;
    }

    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < uvHeight; row++) {
      final uRow = row * uPlane.bytesPerRow;
      final vRow = row * vPlane.bytesPerRow;
      for (int col = 0; col < uvWidth; col++) {
        nv21[offset++] = vPlane.bytes[vRow + col * vPixelStride];
        nv21[offset++] = uPlane.bytes[uRow + col * uPixelStride];
      }
    }

    return nv21;
  }


  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
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
            child: _cameraController == null || !_cameraController!.value.isInitialized
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
