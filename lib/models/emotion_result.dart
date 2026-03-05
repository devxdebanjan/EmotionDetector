class EmotionResult {
  final String emotion;
  final double confidence;

  final double smile;
  final double frown;
  final double stress;
  final double tiredness;

  const EmotionResult({
    required this.emotion,
    required this.confidence,
    this.smile = 0.0,
    this.frown = 0.0,
    this.stress = 0.0,
    this.tiredness = 0.0,
  });

  static const neutral = EmotionResult(
    emotion: 'Neutral',
    confidence: 0.5,
  );

  static const noFace = EmotionResult(
    emotion: 'No face detected',
    confidence: 0.0,
  );
}
