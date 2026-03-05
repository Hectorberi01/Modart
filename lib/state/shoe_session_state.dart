class ShoeSessionState {
  final int steps;
  final double distance;
  final double cadence;
  final double postureScore;
  final double globalScore;
  final bool badPosition;

  const ShoeSessionState({
    this.steps = 0,
    this.distance = 0,
    this.cadence = 0,
    this.postureScore = 100,
    this.globalScore = 0,
    this.badPosition = false,
  });

  ShoeSessionState copyWith({
    int? steps,
    double? distance,
    double? cadence,
    double? postureScore,
    double? globalScore,
    bool? badPosition,
  }) {
    return ShoeSessionState(
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      cadence: cadence ?? this.cadence,
      postureScore: postureScore ?? this.postureScore,
      globalScore: globalScore ?? this.globalScore,
      badPosition: badPosition ?? this.badPosition,
    );
  }
}
