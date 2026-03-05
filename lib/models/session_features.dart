// ─────────────────────────────────────────────────────────────────────────────
// SessionFeatures — KPIs agrégés par session et par pied
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

@immutable
class SessionFeatures {
  const SessionFeatures({
    required this.foot,
    required this.hotspotScore,
    required this.mlpiMean,
    required this.mlpiStd,
    required this.rollScoreMean,
    required this.cadenceMean,
    required this.speedMean,
    required this.asymmetryPct,
    required this.stabilityScore,
    required this.attackHeelPct,
    required this.attackMidPct,
    required this.attackForePct,
    this.ptiByZone = const {},
  });

  /// 'left' ou 'right'.
  final String foot;

  /// Score de surcharge [0–100].
  final double hotspotScore;

  /// MLPI moyen [-1, +1].
  final double mlpiMean;

  /// Écart-type MLPI.
  final double mlpiStd;

  /// Score de déroulé moyen [0–100].
  final double rollScoreMean;

  /// Cadence moyenne (pas/min).
  final double cadenceMean;

  /// Vitesse moyenne (km/h).
  final double speedMean;

  /// Asymétrie G/D (%). 0 = symétrique.
  final double asymmetryPct;

  /// Index de stabilité [0–100].
  final double stabilityScore;

  /// % d'attaque talon.
  final double attackHeelPct;

  /// % d'attaque midfoot.
  final double attackMidPct;

  /// % d'attaque forefoot.
  final double attackForePct;

  /// PTI par zone (JSON).
  final Map<String, double> ptiByZone;

  Map<String, dynamic> toMap() {
    return {
      'foot': foot,
      'hotspot_score': hotspotScore,
      'mlpi_mean': mlpiMean,
      'mlpi_std': mlpiStd,
      'roll_score_mean': rollScoreMean,
      'cadence_mean': cadenceMean,
      'speed_mean': speedMean,
      'asymmetry_pct': asymmetryPct,
      'stability_score': stabilityScore,
      'attack_heel_pct': attackHeelPct,
      'attack_mid_pct': attackMidPct,
      'attack_fore_pct': attackForePct,
      'pti_by_zone': ptiByZone,
    };
  }

  factory SessionFeatures.fromMap(Map<String, dynamic> map) {
    return SessionFeatures(
      foot: map['foot'] as String,
      hotspotScore: (map['hotspot_score'] as num).toDouble(),
      mlpiMean: (map['mlpi_mean'] as num).toDouble(),
      mlpiStd: (map['mlpi_std'] as num).toDouble(),
      rollScoreMean: (map['roll_score_mean'] as num).toDouble(),
      cadenceMean: (map['cadence_mean'] as num).toDouble(),
      speedMean: (map['speed_mean'] as num).toDouble(),
      asymmetryPct: (map['asymmetry_pct'] as num).toDouble(),
      stabilityScore: (map['stability_score'] as num).toDouble(),
      attackHeelPct: (map['attack_heel_pct'] as num).toDouble(),
      attackMidPct: (map['attack_mid_pct'] as num).toDouble(),
      attackForePct: (map['attack_fore_pct'] as num).toDouble(),
      ptiByZone:
          (map['pti_by_zone'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
    );
  }
}
