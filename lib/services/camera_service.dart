import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;

  bool get isReady => _controller != null && _controller!.value.isInitialized;

  Future<void> initialize({
    CameraLensDirection direction = CameraLensDirection.front,
    required void Function(CameraImage image, CameraDescription camera) onFrame,
  }) async {
    _cameras = await availableCameras();
    final selected = _cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      selected,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      _controller!.startImageStream((image) {
        onFrame(image, selected);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error initializing camera: $e");
      }
    }
  }

  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _controller = null;
  }
}
