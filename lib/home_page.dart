import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pages/detection_page.dart';

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
            content: Text(
              'Camera permission is required for emotion detection.',
              style: TextStyle(color: Colors.white),
            ),
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
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 10),
              Text(
                'Analyze your mood in real-time',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  border: Border.all(
                    color: const Color.fromARGB(173, 255, 255, 255),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real Time Analysis',
                      textAlign: TextAlign.left,
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Detect emotions instantly with live camera feed',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  border: Border.all(
                    color: const Color.fromARGB(173, 255, 255, 255),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lighting Check',
                      textAlign: TextAlign.left,
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gives feedback on incorrect lighting conditions',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  border: Border.all(
                    color: const Color.fromARGB(173, 255, 255, 255),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '4 Emotion States',
                      textAlign: TextAlign.left,
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Detects happy, sad, tired, and stressed emotions',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _startDetection(context),
                child: const Text('Start Detection'),
              ),
              const SizedBox(height: 60),
              Text(
                'v1.0.0 | Made by devxdebanjan',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
