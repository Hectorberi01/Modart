import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MetricInfoSheet — BottomSheet expliquant chaque métrique BI
//
// Fournit le contexte indispensable à l'utilisateur : "qu'est-ce que ça
// mesure, pourquoi c'est important, que faire si c'est en alerte ?"
// ─────────────────────────────────────────────────────────────────────────────

class MetricInfo {
  const MetricInfo({
    required this.title,
    required this.unit,
    required this.description,
    required this.whyItMatters,
    required this.normalRange,
    this.alertAdvice,
    this.icon,
    this.color,
  });

  final String title;
  final String unit;
  final String description;
  final String whyItMatters;
  final String normalRange;
  final String? alertAdvice;
  final IconData? icon;
  final Color? color;
}

// ── Catalogue des métriques BI ──────────────────────────────────────────────

abstract final class MetricCatalog {
  static const cadence = MetricInfo(
    title: 'Cadence',
    unit: 'pas/min',
    description:
        'Nombre de pas effectués par minute. La cadence est un indicateur '
        'clé de la qualité de la marche.',
    whyItMatters:
        'Une cadence régulière témoigne d\'une marche stable et efficace. '
        'Une cadence trop basse peut indiquer une fatigue musculaire ou '
        'une douleur compensatoire.',
    normalRange: '90 — 120 pas/min (adulte)',
    alertAdvice:
        'Si la cadence chute sous 80 pas/min, vérifiez s\'il y a '
        'une douleur ou une gêne au niveau du pied.',
    icon: Icons.speed,
  );

  static const speed = MetricInfo(
    title: 'Vitesse',
    unit: 'km/h',
    description:
        'Vitesse moyenne de déplacement estimée à partir des capteurs '
        'de pression et de la cadence.',
    whyItMatters:
        'La vitesse de marche est considérée comme le "6ème signe vital" — '
        'elle corrèle fortement avec l\'état de santé général et la capacité '
        'fonctionnelle.',
    normalRange: '4.0 — 6.0 km/h (marche normale)',
    icon: Icons.directions_walk,
  );

  static const mlpi = MetricInfo(
    title: 'MLPI',
    unit: 'index',
    description:
        'Medial-Lateral Pressure Index — Indice de pression médio-latérale. '
        'Mesure la répartition du poids entre le bord interne (pronation) '
        'et le bord externe (supination) du pied.',
    whyItMatters:
        'Un MLPI décentré signale un déséquilibre de la marche : '
        'une pronation excessive peut fatiguer les tendons, '
        'une supination excessive crée une instabilité latérale.',
    normalRange: '-0.15 à +0.15 (centré)',
    alertAdvice:
        'Au-delà de ±0.30, consultez un podologue pour évaluer '
        'un éventuel trouble de l\'appui.',
    icon: Icons.swap_horiz,
  );

  static const hotspot = MetricInfo(
    title: 'Hotspot Score',
    unit: '/100',
    description:
        'Score de surcharge locale mesurant la concentration de pression '
        'plantaire dans les zones à risque (avant-pied, talon).',
    whyItMatters:
        'Un score élevé (>70) indique une surcharge chronique qui peut '
        'mener à des pathologies : métatarsalgies, fasciite plantaire, '
        'hallux valgus.',
    normalRange: '< 60 : normal · 60-80 : surveillance · > 80 : alerte',
    alertAdvice:
        'Réduisez les activités à impact. Envisagez des semelles '
        'orthopédiques pour redistribuer la pression.',
    icon: Icons.local_fire_department,
  );

  static const rollScore = MetricInfo(
    title: 'Roll Score',
    unit: '/100',
    description:
        'Qualité du déroulé du pas — mesure la fluidité de la transition '
        'talon → médio-pied → avant-pied → orteils.',
    whyItMatters:
        'Un bon déroulé (>70) absorbe les chocs et protège les '
        'articulations. Un déroulé saccadé peut indiquer une raideur '
        'articulaire ou une compensation de douleur.',
    normalRange: '> 70 : bon déroulé · < 50 : déroulé dégradé',
    icon: Icons.trending_up,
  );

  static const asymmetry = MetricInfo(
    title: 'Asymétrie',
    unit: '%',
    description:
        'Différence de charge entre le pied gauche et le pied droit '
        'pendant la marche.',
    whyItMatters:
        'Une asymétrie > 15% révèle une compensation (douleur, '
        'blessure, déséquilibre musculaire). C\'est souvent le premier '
        'signe détectable d\'un problème sous-jacent.',
    normalRange: '< 10% : normal · 10-20% : à surveiller · > 20% : alerte',
    alertAdvice:
        'Identifiez la cause de la compensation. Une asymétrie '
        'persistante mérite une consultation podologique.',
    icon: Icons.balance,
  );

  static const immScore = MetricInfo(
    title: 'Score IMM',
    unit: '/100',
    description:
        'Indice de Maturité de la Marche — score composite évaluant '
        'le développement de la marche chez l\'enfant par rapport '
        'aux normes de son âge (Thevenon 2015).',
    whyItMatters:
        'L\'IMM permet de détecter précocement les troubles de la '
        'marche pédiatrique. Un suivi régulier peut révéler des '
        'retards de maturation qui sont corrigeables si détectés tôt.',
    normalRange: '3-4 ans : 55+ · 5-6 ans : 72+ · 7-10 ans : 80+',
    alertAdvice:
        'Un score < norme - 20 pts sur 3+ sessions consécutives '
        'déclenche une alerte. Consultez un podologue pédiatrique.',
    icon: Icons.child_care,
  );

  static const segment = MetricInfo(
    title: 'Segment de marche',
    unit: '',
    description:
        'Classification en temps réel du type de marche détecté par '
        'les algorithmes SmartSole (normal, course, boiterie, montée, '
        'descente, arrêt).',
    whyItMatters:
        'La segmentation permet d\'adapter l\'analyse au contexte. '
        'Un segment "boiterie" déclenche des alertes spécifiques, '
        'tandis que "course" ajuste les seuils de cadence.',
    normalRange: 'Normal · Course · Montée · Descente · Arrêt',
    icon: Icons.directions_run,
  );
}

// ── Fonctions utilitaires d'affichage ───────────────────────────────────────

/// Ouvre un BottomSheet élégant expliquant la métrique.
void showMetricInfo(BuildContext context, MetricInfo info) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final TextTheme textTheme = Theme.of(context).textTheme;
  final Color accent = info.color ?? SmartSoleColors.biTeal;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color:
              isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
          borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      info.icon ?? Icons.info_outline,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.title, style: textTheme.headlineSmall),
                        if (info.unit.isNotEmpty)
                          Text(
                            info.unit,
                            style: textTheme.bodySmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                info.description,
                style: textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),

              // Pourquoi c'est important
              _InfoSection(
                title: 'Pourquoi c\'est important',
                content: info.whyItMatters,
                icon: Icons.lightbulb_outline,
                color: SmartSoleColors.biWarning,
                isDark: isDark,
                textTheme: textTheme,
              ),
              const SizedBox(height: 12),

              // Plage normale
              _InfoSection(
                title: 'Plage normale',
                content: info.normalRange,
                icon: Icons.check_circle_outline,
                color: SmartSoleColors.biNormal,
                isDark: isDark,
                textTheme: textTheme,
              ),

              // Conseil en cas d'alerte
              if (info.alertAdvice != null) ...[
                const SizedBox(height: 12),
                _InfoSection(
                  title: 'En cas d\'alerte',
                  content: info.alertAdvice!,
                  icon: Icons.warning_amber_rounded,
                  color: SmartSoleColors.biAlert,
                  isDark: isDark,
                  textTheme: textTheme,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Icône "info" cliquable pour ouvrir l'explication d'une métrique.
class MetricInfoButton extends StatelessWidget {
  const MetricInfoButton({
    super.key,
    required this.metric,
    this.size = 16,
    this.color,
  });

  final MetricInfo metric;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => showMetricInfo(context, metric),
      child: Icon(
        Icons.info_outline,
        size: size,
        color:
            color ??
            (isDark
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.20)),
      ),
    );
  }
}

// ── Section info interne ────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.textTheme,
  });

  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final bool isDark;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color:
                        isDark
                            ? SmartSoleColors.textPrimaryDark
                            : SmartSoleColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
