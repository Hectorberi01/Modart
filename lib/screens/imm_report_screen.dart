import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/narrative_card.dart';
import '../widgets/metric_info_sheet.dart';
import '../models/imm_score.dart';
import '../services/mock_data_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMMReportScreen — Rapport Marche Enfant
//
// Score IMM hero, jauge percentile, graphique évolution IMM,
// sous-scores (cadence, asymétrie, double appui, variabilité),
// narration coaching adaptée enfant, alerte fatigue.
// ─────────────────────────────────────────────────────────────────────────────

class IMMReportScreen extends StatelessWidget {
  const IMMReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MockDataService mock = MockDataService.instance;
    final IMMScore current = mock.lucasImmScore;
    final List<IMMScore> history = mock.lucasImmHistory;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final BIState immState =
        current.immPercentile >= 50
            ? BIState.normal
            : current.immPercentile >= 25
            ? BIState.warning
            : BIState.alert;

    return MeshGradientBackground(
      biState: BIState.teal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text('Rapport IMM', style: textTheme.headlineSmall),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => showMetricInfo(context, MetricCatalog.immScore),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              onPressed: () {
                // TODO: Export PDF
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Enfant ────────────────────────────────────────────────
              GlassBentoCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SmartSoleColors.biTeal.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.child_care,
                        size: 22,
                        color: SmartSoleColors.biTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mock.lucasProfile.nickname,
                          style: textTheme.titleLarge,
                        ),
                        Text(
                          '${current.ageMonths ~/ 12} ans ${current.ageMonths % 12} mois',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (current.fatigueDetected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: SmartSoleColors.biWarning.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.battery_3_bar,
                              size: 12,
                              color: SmartSoleColors.biWarning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fatigue',
                              style: textTheme.labelSmall?.copyWith(
                                color: SmartSoleColors.biWarning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Score IMM Hero ─────────────────────────────────────────
              GlassBentoCard(
                accentColor: SmartSoleColors.colorForState(immState),
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Text(
                      current.immScore.toStringAsFixed(0),
                      style: textTheme.displayLarge?.copyWith(
                        color: SmartSoleColors.colorForState(immState),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score de Maturité de Marche',
                      style: textTheme.titleMedium?.copyWith(
                        color: SmartSoleColors.colorForState(immState),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Percentile bar
                    _PercentileBar(
                      percentile: current.immPercentile.toDouble(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Percentile ${current.immPercentile}ᵉ — '
                      '${_percentileLabel(current.immPercentile.toDouble())}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Sous-scores ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SubScoreCard(
                      label: 'Cadence',
                      value: '${current.cadenceScore.toInt()}',
                      unit: 'pas/min',
                      icon: Icons.speed,
                      norm:
                          'Norme : ${IMMScore.cadenceNormForAge(current.ageMonths).toInt()} pas/min',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SubScoreCard(
                      label: 'Asymétrie',
                      value: '${current.asymmetryScore.toInt()}%',
                      unit: '',
                      icon: Icons.compare_arrows,
                      norm: 'Norme : < 15%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SubScoreCard(
                      label: 'Double appui',
                      value: '${current.doubleSupportPct.toInt()}%',
                      unit: '',
                      icon: Icons.sync_alt,
                      norm: 'Norme : 20-30%',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SubScoreCard(
                      label: 'Variabilité',
                      value: '${current.variabilityCv.toInt()}%',
                      unit: 'CV',
                      icon: Icons.auto_graph,
                      norm: 'Norme : < 10%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Évolution IMM ─────────────────────────────────────────
              GlassBentoCard(
                padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('Évolution IMM', style: textTheme.titleLarge),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Text(
                        '${history.length} dernières sessions',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: _buildIMMChart(history, isDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Coaching enfant ───────────────────────────────────────
              NarrativeCard(
                accentColor: SmartSoleColors.biTeal,
                narratives: _childNarratives(current),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIMMChart(List<IMMScore> history, bool isDark) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine:
              (v) => FlLine(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.04),
                strokeWidth: 0.5,
              ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 20,
              getTitlesWidget:
                  (v, _) => Text(
                    v.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isDark
                              ? SmartSoleColors.textTertiaryDark
                              : SmartSoleColors.textTertiaryLight,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget:
                  (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'S${v.toInt() + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isDark
                                ? SmartSoleColors.textTertiaryDark
                                : SmartSoleColors.textTertiaryLight,
                      ),
                    ),
                  ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              history.length,
              (i) => FlSpot(i.toDouble(), history[i].immScore),
            ),
            isCurved: true,
            curveSmoothness: 0.35,
            color: SmartSoleColors.biTeal,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter:
                  (spot, pct, bar, i) => FlDotCirclePainter(
                    radius: 4,
                    color: SmartSoleColors.biTeal,
                    strokeWidth: 2,
                    strokeColor: isDark ? SmartSoleColors.darkBg : Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SmartSoleColors.biTeal.withValues(alpha: 0.15),
                  SmartSoleColors.biTeal.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: SmartSoleDesign.animSlow,
      curve: SmartSoleDesign.animCurve,
    );
  }

  String _percentileLabel(double percentile) {
    if (percentile >= 75) return 'Au-dessus de la moyenne';
    if (percentile >= 50) return 'Dans la moyenne';
    if (percentile >= 25) return 'Légèrement en dessous';
    return 'En dessous de la moyenne — suivi conseillé';
  }

  List<String> _childNarratives(IMMScore score) {
    final List<String> phrases = [];
    if (score.immPercentile < 25) {
      phrases.add(
        'Le score de marche est en dessous de la moyenne pour son âge. '
        'Un bilan podiatrique pourrait confirmer un retard de maturation.',
      );
    }
    if (score.fatigueDetected) {
      phrases.add(
        'La fatigue en fin de session est détectée — la variabilité augmente. '
        'Réduire la durée de marche pourrait aider.',
      );
    }
    if (score.asymmetryScore > 15) {
      phrases.add(
        'L\'asymétrie gauche/droite est au-dessus de la norme. '
        'À surveiller sur les prochaines sessions.',
      );
    }
    if (phrases.isEmpty) {
      phrases.add(
        'La marche progresse bien. Continuez les sessions régulières.',
      );
    }
    return phrases.take(2).toList();
  }
}

// ─── Percentile Bar ─────────────────────────────────────────────────────────

class _PercentileBar extends StatelessWidget {
  const _PercentileBar({required this.percentile});

  final double percentile;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            // Background
            Container(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: (percentile / 100).clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SmartSoleColors.biTeal, SmartSoleColors.biNormal],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-Score Card ─────────────────────────────────────────────────────────

class _SubScoreCard extends StatelessWidget {
  const _SubScoreCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.norm,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String norm;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBentoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: SmartSoleColors.biTeal),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: SmartSoleColors.biTeal,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            norm,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:
                  isDark
                      ? SmartSoleColors.textTertiaryDark
                      : SmartSoleColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
