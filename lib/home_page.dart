import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'detection_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _startDetection(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DetectionPage()),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for emotion detection.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.face_retouching_natural,
                size: 100,
                color: Color(0xFF39FF14), // Neon Green
              ),
              const SizedBox(height: 30),
              Text(
                'Emotion Detector',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Analyze your mood in real-time',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => _startDetection(context),
                child: const Text('Start Detection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
