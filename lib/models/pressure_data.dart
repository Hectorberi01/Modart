// ─────────────────────────────────────────────────────────────────────────────
// PressureData — Données de pression par pied
//
// 4 zones par pied, valeurs normalisées [0, 1].
// Pi_norm = Pi / Σ(P1+P2+P3+P4) — calculé côté app, pas ESP32.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

/// Données de pression normalisées pour un pied (4 zones).
@immutable
class PressureData {
  const PressureData({
    required this.heel,
    required this.midfoot,
    required this.forefoot,
    required this.toe,
  });

  /// Pression normalisée zone talon [0, 1].
  final double heel;

  /// Pression normalisée zone médio-pied [0, 1].
  final double midfoot;

  /// Pression normalisée zone avant-pied [0, 1].
  final double forefoot;

  /// Pression normalisée zone orteils [0, 1].
  final double toe;

  /// Somme des zones (devrait être ~1.0 si normalisé).
  double get total => heel + midfoot + forefoot + toe;

  /// Zone avec la pression maximale.
  String get dominantZone {
    final Map<String, double> zones = {
      'heel': heel,
      'midfoot': midfoot,
      'forefoot': forefoot,
      'toe': toe,
    };
    return zones.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Vérifie si une zone est en hotspot (> seuil).
  bool isHotspot(double threshold) {
    return heel > threshold ||
        midfoot > threshold ||
        forefoot > threshold ||
        toe > threshold;
  }

  /// Retourne les zones en hotspot.
  List<String> hotspotZones(double threshold) {
    final List<String> zones = [];
    if (heel > threshold) zones.add('heel');
    if (midfoot > threshold) zones.add('midfoot');
    if (forefoot > threshold) zones.add('forefoot');
    if (toe > threshold) zones.add('toe');
    return zones;
  }

  /// Pression d'une zone par index (0=heel, 1=midfoot, 2=forefoot, 3=toe).
  double operator [](int index) {
    return switch (index) {
      0 => heel,
      1 => midfoot,
      2 => forefoot,
      3 => toe,
      _ => throw RangeError.index(index, this, 'index', null, 4),
    };
  }

  /// Crée une PressureData à partir de valeurs brutes ADC (0-4095).
  factory PressureData.fromRaw({
    required int p1,
    required int p2,
    required int p3,
    required int p4,
  }) {
    final double sum = (p1 + p2 + p3 + p4).toDouble();
    if (sum == 0) return PressureData.zero;
    return PressureData(
      heel: p1 / sum,
      midfoot: p2 / sum,
      forefoot: p3 / sum,
      toe: p4 / sum,
    );
  }

  /// Valeur nulle (aucune pression).
  static const PressureData zero = PressureData(
    heel: 0,
    midfoot: 0,
    forefoot: 0,
    toe: 0,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PressureData &&
        other.heel == heel &&
        other.midfoot == midfoot &&
        other.forefoot == forefoot &&
        other.toe == toe;
  }

  @override
  int get hashCode => Object.hash(heel, midfoot, forefoot, toe);

  @override
  String toString() =>
      'PressureData(heel: ${heel.toStringAsFixed(2)}, mid: ${midfoot.toStringAsFixed(2)}, fore: ${forefoot.toStringAsFixed(2)}, toe: ${toe.toStringAsFixed(2)})';

  Map<String, dynamic> toMap() {
    return {'heel': heel, 'midfoot': midfoot, 'forefoot': forefoot, 'toe': toe};
  }

  factory PressureData.fromMap(Map<String, dynamic> map) {
    return PressureData(
      heel: (map['heel'] as num).toDouble(),
      midfoot: (map['midfoot'] as num).toDouble(),
      forefoot: (map['forefoot'] as num).toDouble(),
      toe: (map['toe'] as num).toDouble(),
    );
  }
}
