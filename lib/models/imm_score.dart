// ─────────────────────────────────────────────────────────────────────────────
// IMMScore — Indice de Maturité de la Marche (Persona 2 / Enfant)
//
// Score composite positionné sur courbe normative par âge.
// Normes : Thevenon 2015, Dusing & Thorpe 2007, Gouelle 2016.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

@immutable
class IMMScore {
  const IMMScore({
    required this.sessionId,
    required this.childId,
    required this.ageMonths,
    required this.immScore,
    required this.immPercentile,
    required this.cadenceScore,
    required this.asymmetryScore,
    required this.doubleSupportPct,
    required this.variabilityCv,
    required this.fatigueDetected,
    this.createdAt,
  });

  final int sessionId;
  final int childId;

  /// Âge de l'enfant en mois au moment du score.
  final int ageMonths;

  /// Score IMM composite [0–100].
  final double immScore;

  /// Percentile par rapport à la tranche d'âge.
  final int immPercentile;

  /// Score de cadence pour l'âge.
  final double cadenceScore;

  /// Score d'asymétrie pour l'âge.
  final double asymmetryScore;

  /// Double appui en % du cycle de marche.
  final double doubleSupportPct;

  /// Variabilité de la cadence (CV%).
  final double variabilityCv;

  /// Signature fatigue détectée ?
  final bool fatigueDetected;

  final DateTime? createdAt;

  /// Norme de cadence par tranche d'âge (Thevenon 2015).
  static double cadenceNormForAge(int ageMonths) {
    if (ageMonths < 48) return 147.0; // 3-4 ans
    if (ageMonths < 72) return 138.0; // 5-6 ans
    if (ageMonths < 120) return 127.5; // 7-10 ans
    return 115.0; // > 10 ans
  }

  /// Norme de score IMM par tranche d'âge.
  static double immNormForAge(int ageMonths) {
    if (ageMonths < 48) return 55.0;
    if (ageMonths < 72) return 72.5;
    if (ageMonths < 120) return 80.0;
    return 85.0;
  }

  /// Vérifie si le score est en alerte (< norme - 20 pts sur 3+ sessions).
  bool isAlert() {
    return immScore < (immNormForAge(ageMonths) - 20);
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'child_id': childId,
      'age_months': ageMonths,
      'imm_score': immScore,
      'imm_percentile': immPercentile,
      'cadence_score': cadenceScore,
      'asymmetry_score': asymmetryScore,
      'double_support_pct': doubleSupportPct,
      'variability_cv': variabilityCv,
      'fatigue_detected': fatigueDetected ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory IMMScore.fromMap(Map<String, dynamic> map) {
    return IMMScore(
      sessionId: map['session_id'] as int,
      childId: map['child_id'] as int,
      ageMonths: map['age_months'] as int,
      immScore: (map['imm_score'] as num).toDouble(),
      immPercentile: map['imm_percentile'] as int,
      cadenceScore: (map['cadence_score'] as num).toDouble(),
      asymmetryScore: (map['asymmetry_score'] as num).toDouble(),
      doubleSupportPct: (map['double_support_pct'] as num).toDouble(),
      variabilityCv: (map['variability_cv'] as num).toDouble(),
      fatigueDetected: map['fatigue_detected'] == 1,
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : null,
    );
  }
}
