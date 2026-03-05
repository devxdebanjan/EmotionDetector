import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmotionDetectorApp());
}

class EmotionDetectorApp extends StatelessWidget {
  const EmotionDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Detector',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF39FF14), // Neon green
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF39FF14),
          secondary: Colors.grey,
          surface: Color(0xFF1E1E1E), 
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, letterSpacing: 1.0),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color:  Color.fromARGB(255, 221, 221, 221)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF39FF14),
          foregroundColor: Colors.black,
          shadowColor: const Color(0xFF39FF14), 
          elevation: 20,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
