import 'package:flutter/material.dart';
import '../models/session_features.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionRecommendations — Recommandations dynamiques post-session
//
// Analyse les SessionFeatures sur 5 axes (surcharge, asymétrie, déroulé,
// stabilité, risque combiné) et génère jusqu'à 3 items priorisés.
// Tri : alert priority=0 (critique) → alert priority=1 → warning → normal.
// Animations staggerées (TweenAnimationBuilder, 100ms décalage par item).
// Badge "Urgent" rouge pour les alertes critiques (priority=0).
// ─────────────────────────────────────────────────────────────────────────────

class SessionRecommendations extends StatelessWidget {
  final SessionFeatures features;

  const SessionRecommendations({super.key, required this.features});

  List<_Rec> _buildRecs() {
    final recs = <_Rec>[];

    // ── Surcharge plantaire ─────────────────────────────────────────────────
    if (features.hotspotScore > 70) {
      recs.add(_Rec(
        icon: Icons.local_fire_department_rounded,
        state: BIState.alert,
        title: 'Surcharge plantaire détectée',
        body:
            'Score ${features.hotspotScore.toInt()}/100 — pression localisée élevée. '
            'Réduisez l\'intensité et vérifiez le positionnement de la semelle.',
      ));
    } else if (features.hotspotScore > 50) {
      recs.add(_Rec(
        icon: Icons.local_fire_department_rounded,
        state: BIState.warning,
        title: 'Pression plantaire à surveiller',
        body:
            'Surcharge modérée (${features.hotspotScore.toInt()}/100). '
            'Maintien du niveau d\'activité actuel conseillé.',
      ));
    }

    // ── Asymétrie G/D ───────────────────────────────────────────────────────
    if (features.asymmetryPct > 15) {
      recs.add(_Rec(
        icon: Icons.compare_arrows_rounded,
        state: BIState.alert,
        title: 'Asymétrie importante (${features.asymmetryPct.toInt()}%)',
        body:
            'Déséquilibre G/D significatif détecté. '
            'Consultez un spécialiste pour évaluer votre alignement postural.',
      ));
    } else if (features.asymmetryPct > 7) {
      recs.add(_Rec(
        icon: Icons.compare_arrows_rounded,
        state: BIState.warning,
        title: 'Légère asymétrie (${features.asymmetryPct.toInt()}%)',
        body:
            'Concentrez-vous sur le déroulé du pied le plus faible. '
            'Des exercices de proprioception peuvent corriger ce déséquilibre.',
      ));
    }

    // ── Qualité du déroulé ──────────────────────────────────────────────────
    if (features.rollScoreMean < 50) {
      recs.add(_Rec(
        icon: Icons.trending_up_rounded,
        state: BIState.alert,
        title: 'Déroulé insuffisant',
        body:
            'Score ${features.rollScoreMean.toInt()}/100 — phase talon-orteils incomplète. '
            'Travaillez la flexion de cheville et l\'extension du gros orteil.',
      ));
    } else if (features.rollScoreMean < 70) {
      recs.add(_Rec(
        icon: Icons.trending_up_rounded,
        state: BIState.warning,
        title: 'Déroulé à améliorer',
        body:
            'Score ${features.rollScoreMean.toInt()}/100. '
            'Des étirements des mollets et de la voûte plantaire peuvent améliorer la qualité du pas.',
      ));
    }

    // ── Stabilité ───────────────────────────────────────────────────────────
    if (features.stabilityScore < 50) {
      recs.add(_Rec(
        icon: Icons.balance_rounded,
        state: BIState.warning,
        title: 'Stabilité à renforcer',
        body:
            'Index ${features.stabilityScore.toInt()}/100. '
            'Exercices d\'équilibre unipodal et renforcement des chevilles recommandés.',
      ));
    }

    // ── Risque combiné ──────────────────────────────────────────────────────
    if (features.hotspotScore > 50 && features.asymmetryPct > 10) {
      recs.add(_Rec(
        icon: Icons.warning_rounded,
        state: BIState.alert,
        title: 'Risque de blessure à surveiller',
        body:
            'La combinaison surcharge plantaire + asymétrie G/D '
            'augmente le risque de tendinopathie ou fascéite plantaire. '
            'Repos partiel et consultation recommandés.',
        priority: 0,
      ));
    }

    // ── Tout est dans la norme ──────────────────────────────────────────────
    if (recs.isEmpty) {
      recs.add(_Rec(
        icon: Icons.verified_rounded,
        state: BIState.normal,
        title: 'Tous les indicateurs dans la norme',
        body:
            'Excellent travail ! Votre dynamique de marche est équilibrée et efficace. '
            'Continuez votre programme actuel.',
      ));
    }

    // ── Tri : alert priority=0 → alert priority=1 → warning → normal ────────
    recs.sort((a, b) {
      final stateOrder = _stateOrder(a.state).compareTo(_stateOrder(b.state));
      if (stateOrder != 0) return stateOrder;
      return a.priority.compareTo(b.priority);
    });

    return recs.take(3).toList();
  }

  static int _stateOrder(BIState state) {
    switch (state) {
      case BIState.alert:
        return 0;
      case BIState.warning:
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recs = _buildRecs();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ───────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SmartSoleColors.biNormal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: SmartSoleColors.biNormal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recommandations',
                style: TextStyle(
                  fontFamily: 'Articulat CF',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: SmartSoleColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Liste des recommandations avec animations staggerées ───────────
          ...List.generate(recs.length, (i) {
            final rec = recs[i];
            final Color accent = SmartSoleColors.colorForState(rec.state);
            final bool isLast = i == recs.length - 1;
            final bool isUrgent =
                rec.state == BIState.alert && rec.priority == 0;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (i * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône colorée
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(rec.icon, size: 15, color: accent),
                      ),
                      const SizedBox(width: 12),
                      // Texte + badge "Urgent"
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    rec.title,
                                    style: TextStyle(
                                      fontFamily: 'Articulat CF',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                    ),
                                  ),
                                ),
                                if (isUrgent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SmartSoleColors.biAlert
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: SmartSoleColors.biAlert
                                            .withValues(alpha: 0.40),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'Urgent',
                                      style: TextStyle(
                                        fontFamily: 'Articulat CF',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: SmartSoleColors.biAlert,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              rec.body,
                              style: TextStyle(
                                fontFamily: 'Articulat CF',
                                fontSize: 12,
                                color:
                                    isDark
                                        ? SmartSoleColors.textSecondaryDark
                                        : SmartSoleColors.textSecondaryLight,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Modèle interne ───────────────────────────────────────────────────────────

class _Rec {
  const _Rec({
    required this.icon,
    required this.state,
    required this.title,
    required this.body,
    this.priority = 1,
  });

  final IconData icon;
  final BIState state;
  final String title;
  final String body;
  final int priority; // 0 = critique (badge "Urgent"), 1 = normal
}
