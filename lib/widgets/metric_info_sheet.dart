import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MetricInfoSheet — BottomSheet expliquant chaque métrique BI
//
// Fournit le contexte indispensable à l'utilisateur : "qu'est-ce que ça
// mesure, pourquoi c'est important, que faire si c'est en alerte ?"
// ─────────────────────────────────────────────────────────────────────────────

class MetricInfo {
  const MetricInfo({
    required this.key,
    required this.title,
    required this.unit,
    required this.description,
    required this.whyItMatters,
    required this.normalRange,
    this.alertAdvice,
    this.icon,
    this.color,
  });

  final String key;
  final String title;
  final String unit;
  final String description;
  final String whyItMatters;
  final String normalRange;
  final String? alertAdvice;
  final IconData? icon;
  final Color? color;

  /// Returns a localized copy using AppLocalizations translation keys.
  MetricInfo localized(AppLocalizations l) {
    final t = l.t('metric${key}Title');
    // If no translation found (returns the key), fall back to original
    if (t == 'metric${key}Title') return this;
    return MetricInfo(
      key: key,
      title: l.t('metric${key}Title'),
      unit: l.t('metric${key}Unit'),
      description: l.t('metric${key}Desc'),
      whyItMatters: l.t('metric${key}Why'),
      normalRange: l.t('metric${key}Range'),
      alertAdvice: alertAdvice != null ? l.t('metric${key}Alert') : null,
      icon: icon,
      color: color,
    );
  }
}

// ── Catalogue des métriques BI ──────────────────────────────────────────────

abstract final class MetricCatalog {
  static const cadence = MetricInfo(
    key: 'Cadence',
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
    key: 'Speed',
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
    key: 'Mlpi',
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
    key: 'Hotspot',
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
    key: 'Roll',
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
    key: 'Asymmetry',
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
    key: 'Imm',
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
    key: 'Segment',
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
  final l = AppLocalizations.of(context);
  info = info.localized(l);
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
                title: l.metricWhyImportant,
                content: info.whyItMatters,
                icon: Icons.lightbulb_outline,
                color: SmartSoleColors.biWarning,
                isDark: isDark,
                textTheme: textTheme,
              ),
              const SizedBox(height: 12),

              // Plage normale
              _InfoSection(
                title: l.metricNormalRange,
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
                  title: l.metricAlertAdvice,
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

// ── MetricTooltipWrapper — Long-press tooltip bulle ─────────────────────────
//
// Enveloppe un widget enfant. Au long-press, une bulle apparaît avec
// le titre et la description courte de la métrique.
// Au tap normal : ouvre le BottomSheet complet.

class MetricTooltipWrapper extends StatefulWidget {
  const MetricTooltipWrapper({
    super.key,
    required this.metric,
    required this.child,
  });

  final MetricInfo metric;
  final Widget child;

  @override
  State<MetricTooltipWrapper> createState() => _MetricTooltipWrapperState();
}

class _MetricTooltipWrapperState extends State<MetricTooltipWrapper>
    with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _opacityAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _hideTooltip();
    _animCtrl.dispose();
    super.dispose();
  }

  void _showTooltip() {
    _hideTooltip();
    final RenderBox? box =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset offset = box.localToGlobal(Offset.zero);
    final Size childSize = box.size;
    final double screenWidth = MediaQuery.of(context).size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        // Position above the widget
        const double tooltipMaxW = 280;
        double left = offset.dx + childSize.width / 2 - tooltipMaxW / 2;
        if (left < 12) left = 12;
        if (left + tooltipMaxW > screenWidth - 12) {
          left = screenWidth - tooltipMaxW - 12;
        }
        final double top = offset.dy - 10;

        return Positioned(
          left: left,
          top: 0,
          child: FadeTransition(
            opacity: _opacityAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.bottomCenter,
              child: _TooltipBubble(
                metric: widget.metric,
                maxWidth: tooltipMaxW,
                bottomY: top,
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward();
  }

  void _hideTooltip() {
    if (_overlayEntry != null) {
      _animCtrl.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _childKey,
      onTap: () => showMetricInfo(context, widget.metric),
      onLongPress: _showTooltip,
      onLongPressEnd: (_) => _hideTooltip(),
      child: widget.child,
    );
  }
}

// ── Tooltip Bubble ──────────────────────────────────────────────────────────

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.metric,
    required this.maxWidth,
    required this.bottomY,
  });

  final MetricInfo metric;
  final double maxWidth;
  final double bottomY;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final localizedMetric = metric.localized(l);
    final Color accent = localizedMetric.color ?? SmartSoleColors.biTeal;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: EdgeInsets.only(top: (bottomY - 120).clamp(20, bottomY - 20)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? SmartSoleColors.tooltipBg : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(SmartSoleColors.tooltipRadius),
        border: Border.all(
          color:
              isDark
                  ? SmartSoleColors.tooltipBorder
                  : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(localizedMetric.icon ?? Icons.info_outline, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                localizedMetric.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              if (localizedMetric.unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '(${localizedMetric.unit})',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isDark
                            ? SmartSoleColors.textTertiaryDark
                            : SmartSoleColors.textTertiaryLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizedMetric.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color:
                  isDark
                      ? SmartSoleColors.textSecondaryDark
                      : SmartSoleColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.metricTapMore,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accent.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
