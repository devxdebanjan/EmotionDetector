import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ImageConverter {
  ImageConverter._();

  static String analyzeLighting(CameraImage image) {      
    if (image.format.group == ImageFormatGroup.yuv420 ||
        image.format.group == ImageFormatGroup.nv21) {
      final Uint8List yPlane = image.planes[0].bytes;
      int totalLuma = 0;
      for (int i = 0; i < yPlane.length; i += 10) {
        totalLuma += yPlane[i];
      }
      final double avgLuma = totalLuma / (yPlane.length / 10);

      if (avgLuma < 50) return "Too Dim! Move to brighter lighting.";
      if (avgLuma > 200) return "Too Bright! Lower the lighting.";
      return "Good Lighting";
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final Uint8List bytes = image.planes[0].bytes;
      int totalLuma = 0;
      for (int i = 0; i < bytes.length; i += 40) {
        totalLuma += (0.114 * bytes[i] + 0.587 * bytes[i + 1] + 0.299 * bytes[i + 2]).toInt();
      }
      final double avgLuma = totalLuma / (bytes.length / 40);

      if (avgLuma < 50) return "Too Dim! Move to brighter lighting.";
      if (avgLuma > 200) return "Too Bright! Lower the lighting.";
      return "Good Lighting";
    }
    return "Good Lighting";
  }

  static InputImage? convert(CameraImage image, CameraDescription camera) {   
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
        bytes = _yuv420ToNv21(image);
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

  static Uint8List _yuv420ToNv21(CameraImage image) {   
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
}
