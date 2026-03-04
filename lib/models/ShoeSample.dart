class ShoeSample {
  final int steps;
  final double angleX;
  final double angleY;
  final bool badPosition;
  final DateTime timestamp;

  ShoeSample({
    required this.steps,
    required this.angleX,
    required this.angleY,
    required this.badPosition,
    required this.timestamp,
  });
}

class SessionResult {
  final int totalSteps;
  final Duration badPostureDuration;
  final double postureScore;

  SessionResult({
    required this.totalSteps,
    required this.badPostureDuration,
    required this.postureScore,
  });
}
