import 'dart:math';
import '../models/pressure_data.dart';
import '../models/session_features.dart';
import '../models/imm_score.dart';
import '../models/user_profile.dart';
import '../widgets/segment_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MockDataService — Données simulées par persona
//
// 3 jeux de données réalistes (Thomas, Lucas, Dr. Amara) tirés du CdC v4.
// Utilisé en mode démo et pour le développement sans ESP32 physique.
// ─────────────────────────────────────────────────────────────────────────────

class MockDataService {
  MockDataService._();
  static final MockDataService instance = MockDataService._();

  final Random _rng = Random(42); // Seed fixe pour reproductibilité

  // ── PERSONA 1 — Thomas (Actif Urbain) ─────────────────────────────────────

  /// Pression live simulée pour Thomas — avant-pied droit en surcharge.
  PressureData get thomasLeftPressure => PressureData(
    heel: 0.30 + _variance(0.02),
    midfoot: 0.22 + _variance(0.02),
    forefoot: 0.35 + _variance(0.03),
    toe: 0.13 + _variance(0.01),
  );

  PressureData get thomasRightPressure => PressureData(
    heel: 0.25 + _variance(0.02),
    midfoot: 0.18 + _variance(0.02),
    forefoot: 0.42 + _variance(0.03), // Surcharge avant-pied droit
    toe: 0.15 + _variance(0.01),
  );

  SessionFeatures get thomasSessionFeatures => SessionFeatures(
    foot: 'global',
    hotspotScore: 72,
    mlpiMean: -0.22,
    mlpiStd: 0.08,
    rollScoreMean: 62,
    cadenceMean: 98,
    speedMean: 5.2,
    asymmetryPct: 18,
    stabilityScore: 68,
    attackHeelPct: 55,
    attackMidPct: 15,
    attackForePct: 30,
    ptiByZone: {'heel': 0.30, 'midfoot': 0.20, 'forefoot': 0.38, 'toe': 0.12},
  );

  /// Mock session Thomas — données de la dernière session.
  Map<String, dynamic> get thomasSessionData => {
    'totalSteps': 8432,
    'distance': 5.8,
    'duration': Duration(minutes: 52, seconds: 14),
    'avgSpeed': 5.2,
    'maxSpeed': 7.8,
    'cadence': 98,
    'painPre': 2,
    'painPost': 4,
    'segment': WalkSegment.normal,
    'mlpi': -0.22,
    'rollScore': 62,
    'asymmetry': 0.18,
    'hotspot': {'zone': 'forefoot_right', 'level': 'high', 'sessions': 4},
  };

  // ── PERSONA 2 — Lucas (Enfant, 5 ans) ─────────────────────────────────────

  ChildProfile get lucasProfile => const ChildProfile(
    id: 1,
    nickname: 'Lucas',
    birthMonth: 3,
    birthYear: 2021,
    heightCm: 110,
  );

  PressureData get lucasLeftPressure => PressureData(
    heel: 0.28 + _variance(0.03),
    midfoot: 0.22 + _variance(0.02),
    forefoot: 0.35 + _variance(0.03),
    toe: 0.15 + _variance(0.02),
  );

  PressureData get lucasRightPressure => PressureData(
    heel: 0.26 + _variance(0.03),
    midfoot: 0.20 + _variance(0.02),
    forefoot: 0.38 + _variance(0.03),
    toe: 0.16 + _variance(0.01),
  );

  IMMScore get lucasImmScore => const IMMScore(
    sessionId: 1,
    childId: 1,
    ageMonths: 60, // 5 ans
    immScore: 67,
    immPercentile: 35,
    cadenceScore: 141,
    asymmetryScore: 13,
    doubleSupportPct: 28,
    variabilityCv: 12,
    fatigueDetected: true,
  );

  /// Historique IMM pour Lucas (4 sessions).
  List<IMMScore> get lucasImmHistory => [
    const IMMScore(
      sessionId: 1,
      childId: 1,
      ageMonths: 59,
      immScore: 59,
      immPercentile: 22,
      cadenceScore: 138,
      asymmetryScore: 16,
      doubleSupportPct: 30,
      variabilityCv: 15,
      fatigueDetected: true,
    ),
    const IMMScore(
      sessionId: 2,
      childId: 1,
      ageMonths: 59,
      immScore: 62,
      immPercentile: 27,
      cadenceScore: 139,
      asymmetryScore: 14,
      doubleSupportPct: 29,
      variabilityCv: 13,
      fatigueDetected: true,
    ),
    const IMMScore(
      sessionId: 3,
      childId: 1,
      ageMonths: 60,
      immScore: 65,
      immPercentile: 32,
      cadenceScore: 140,
      asymmetryScore: 13,
      doubleSupportPct: 28,
      variabilityCv: 12,
      fatigueDetected: false,
    ),
    const IMMScore(
      sessionId: 4,
      childId: 1,
      ageMonths: 60,
      immScore: 67,
      immPercentile: 35,
      cadenceScore: 141,
      asymmetryScore: 13,
      doubleSupportPct: 28,
      variabilityCv: 12,
      fatigueDetected: true,
    ),
  ];

  // ── PERSONA 3 — Dr. Amara (Pro Santé) ─────────────────────────────────────

  PressureData get amaraPatientLeftPressure => PressureData(
    heel: 0.28 + _variance(0.02),
    midfoot: 0.17 + _variance(0.02),
    forefoot: 0.40 + _variance(0.03),
    toe: 0.15 + _variance(0.01),
  );

  PressureData get amaraPatientRightPressure => PressureData(
    heel: 0.30 + _variance(0.02),
    midfoot: 0.15 + _variance(0.02),
    forefoot: 0.44 + _variance(0.03), // Surcharge chronique
    toe: 0.11 + _variance(0.01),
  );

  /// Données comparaison J0→J30 pour le patient de Dr. Amara.
  Map<String, List<double>> get amaraJ0VsJ30 => {
    'rollScore': [54.0, 66.0],
    'asymmetry': [0.28, 0.24],
    'mlpi': [-0.18, -0.22],
    'hotspotScore': [82.0, 71.0],
  };

  SessionFeatures get amaraPatientFeatures => const SessionFeatures(
    foot: 'global',
    hotspotScore: 78,
    mlpiMean: -0.20,
    mlpiStd: 0.10,
    rollScoreMean: 66,
    cadenceMean: 92,
    speedMean: 4.8,
    asymmetryPct: 24,
    stabilityScore: 56,
    attackHeelPct: 42,
    attackMidPct: 18,
    attackForePct: 40,
    ptiByZone: {'heel': 0.29, 'midfoot': 0.16, 'forefoot': 0.42, 'toe': 0.13},
  );

  // ── Générateur de sessions historiques (30 jours) ─────────────────────────

  /// Génère 30 jours de features de session avec variance naturelle.
  List<SessionFeatures> generateHistory({
    required double baseHotspot,
    required double baseMlpi,
    required double baseRollScore,
    required double baseCadence,
    required double baseAsymmetry,
    int days = 30,
  }) {
    return List.generate(days, (i) {
      // Tendance légère amélioration sur le mois
      final double trend = i / days * 0.1;
      return SessionFeatures(
        foot: 'global',
        hotspotScore: (baseHotspot - trend * 10 + _variance(5)).clamp(0, 100),
        mlpiMean: baseMlpi + _variance(0.05),
        mlpiStd: 0.08 + _variance(0.02),
        rollScoreMean: (baseRollScore + trend * 8 + _variance(3)).clamp(0, 100),
        cadenceMean: baseCadence + _variance(4),
        speedMean: 5.0 + _variance(0.5),
        asymmetryPct: (baseAsymmetry - trend * 2 + _variance(2)).clamp(0, 50),
        stabilityScore: (65 + trend * 5 + _variance(3)).clamp(0, 100),
        attackHeelPct: 55 + _variance(5),
        attackMidPct: 15 + _variance(3),
        attackForePct: 30 + _variance(5),
      );
    });
  }

  /// Génère un historique de douleur (30 jours).
  List<int> generatePainHistory({int days = 30, int basePain = 4}) {
    return List.generate(days, (i) {
      return (basePain + _variance(1.5).round()).clamp(0, 10);
    });
  }

  // ── Utilitaire ────────────────────────────────────────────────────────────

  double _variance(double range) {
    return (_rng.nextDouble() - 0.5) * 2 * range;
  }
}
