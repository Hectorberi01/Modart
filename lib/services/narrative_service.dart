import '../models/session_features.dart';
import '../models/imm_score.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NarrativeService — Système de narration BI automatique
//
// 6 règles du CdC v4. Génère 2 phrases coach après chaque session.
// Pur système if/else — aucun LLM pour le MVP.
// ─────────────────────────────────────────────────────────────────────────────

class NarrativeService {
  NarrativeService._();
  static final NarrativeService instance = NarrativeService._();

  /// Génère les phrases narratives post-session (max 2).
  ///
  /// [features] — KPIs de la session courante.
  /// [previousRollScore] — Score déroulé de la session précédente (optionnel).
  /// [hotspotSessionCount] — Nombre de sessions consécutives avec hotspot.
  /// [childName] — Prénom de l'enfant (Persona 2 uniquement).
  /// [immScore] — Score IMM (Persona 2 uniquement).
  List<String> generateNarrative({
    required SessionFeatures features,
    double? previousRollScore,
    int hotspotSessionCount = 0,
    String? childName,
    IMMScore? immScore,
  }) {
    final List<String> phrases = [];

    // ── Règle 1 : Hotspot chronique ─────────────────────────────────────────
    // Si hotspot_level >= 'high' ET sessions_count >= 3
    if (features.hotspotScore > 60 && hotspotSessionCount >= 3) {
      final String zone = _dominantZoneName(features);
      phrases.add(
        'Ta zone $zone surcharge depuis $hotspotSessionCount sessions. '
        '${_adviceForZone(zone)}',
      );
    }

    // ── Règle 2 : Déroulé insuffisant ───────────────────────────────────────
    if (features.rollScoreMean < 50 && phrases.length < 2) {
      phrases.add(
        'Ton déroulé plantaire est incomplet. '
        'Essaie de conscientiser l\'attaque talon.',
      );
    }

    // ── Règle 3 : Déroulé en amélioration ───────────────────────────────────
    if (previousRollScore != null &&
        features.rollScoreMean > previousRollScore + 5 &&
        phrases.length < 2) {
      final int delta = (features.rollScoreMean - previousRollScore).round();
      phrases.add(
        'Ton déroulé s\'améliore — +$delta pts cette semaine. Continue.',
      );
    }

    // ── Règle 4 : Asymétrie élevée ──────────────────────────────────────────
    if (features.asymmetryPct > 20 && phrases.length < 2) {
      final String side = features.mlpiMean < 0 ? 'gauche' : 'droit';
      phrases.add(
        'Ton pied $side compense ${features.asymmetryPct.toInt()}% de plus '
        'que l\'autre. À surveiller.',
      );
    }

    // ── Règle 5 : IMM enfant en dessous de la norme (Persona 2) ────────────
    if (immScore != null &&
        immScore.immPercentile < 25 &&
        hotspotSessionCount >= 3 &&
        childName != null &&
        phrases.length < 2) {
      phrases.add(
        'Le score de marche de $childName est en dessous de la moyenne '
        'pour son âge. Un bilan podiatrique pourrait être utile.',
      );
    }

    // ── Règle 6 : Tout est normal ───────────────────────────────────────────
    if (phrases.isEmpty) {
      phrases.add(
        'Belle session. Ton équilibre était stable '
        'et ton déroulé dans les normes.',
      );
    }

    // Garantir max 2 phrases
    return phrases.take(2).toList();
  }

  /// Retourne le nom de la zone dominante en surcharge.
  String _dominantZoneName(SessionFeatures features) {
    final Map<String, double> zones = features.ptiByZone;
    if (zones.isEmpty) return 'avant-pied';

    final entry = zones.entries.reduce((a, b) => a.value > b.value ? a : b);

    return switch (entry.key) {
      'heel' => 'talon',
      'midfoot' => 'médio-pied',
      'forefoot' => 'avant-pied',
      'toe' => 'orteils',
      _ => entry.key,
    };
  }

  /// Conseil personnalisé selon la zone de surcharge.
  String _adviceForZone(String zone) {
    return switch (zone) {
      'avant-pied' => 'Pense à répartir la charge vers le talon.',
      'talon' => 'L\'attaque talon excessive peut fatiguer les articulations.',
      'médio-pied' => 'La charge au médio-pied peut indiquer un pied plat.',
      'orteils' =>
        'La surcharge des orteils peut venir d\'une chaussure trop courte.',
      _ => 'Continue à surveiller cette zone.',
    };
  }
}
