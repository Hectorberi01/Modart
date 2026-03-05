import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/narrative_card.dart';
import '../widgets/metric_info_sheet.dart';
import '../models/session.dart';
import '../providers.dart';
import '../state/auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMMReportScreen — Rapport Marche Enfant (données réelles)
//
// Calcule un score IMM à partir des vraies sessions enregistrées.
// ─────────────────────────────────────────────────────────────────────────────

class IMMReportScreen extends ConsumerWidget {
  const IMMReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final auth = ref.watch(authProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    // Get child name from auth profile or default
    final childName = auth.userProfile?.childProfile?.nickname ?? l.navChildTracking;
    final childAgeMonths = auth.userProfile?.childProfile?.ageMonths ?? 48;

    return MeshGradientBackground(
      biState: BIState.teal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(l.immTitle, style: textTheme.headlineSmall),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => showMetricInfo(context, MetricCatalog.immScore),
            ),
          ],
        ),
        body: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SmartSoleColors.biTeal, strokeWidth: 2)),
          error: (e, _) => Center(child: Text('${l.trendsError}$e', style: textTheme.bodyMedium)),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.child_care, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 16),
                    Text(l.immNoSession, style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(l.immNoSessionDesc, style: textTheme.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            // Compute IMM metrics from real sessions
            final latestSession = sessions.last;
            final immScore = _computeImmScore(latestSession);
            final immPercentile = _computePercentile(immScore, childAgeMonths);
            final cadenceEstimate = _estimateCadence(latestSession);
            final asymmetryEstimate = ((100 - latestSession.postureScore) * 0.4).clamp(0, 50);
            final doubleSupportPct = (25 + (100 - latestSession.postureScore) * 0.15).clamp(15, 45);
            final variabilityCv = (8 + (100 - latestSession.postureScore) * 0.12).clamp(3, 25);
            final fatigueDetected = latestSession.postureScore < 50;

            final BIState immState = immPercentile >= 50 ? BIState.normal : immPercentile >= 25 ? BIState.warning : BIState.alert;

            // History of IMM scores from all sessions
            final immHistory = sessions.map((s) => _computeImmScore(s)).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ── Enfant
                  GlassBentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: SmartSoleColors.biTeal.withValues(alpha: 0.12)),
                          child: const Icon(Icons.child_care, size: 22, color: SmartSoleColors.biTeal),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(childName, style: textTheme.titleLarge),
                            Text('${childAgeMonths ~/ 12} ${l.locale.languageCode == 'fr' ? 'ans' : 'yrs'} ${childAgeMonths % 12} ${l.locale.languageCode == 'fr' ? 'mois' : 'mo'}', style: textTheme.bodySmall),
                          ],
                        ),
                        const Spacer(),
                        if (fatigueDetected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: SmartSoleColors.biWarning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.battery_3_bar, size: 12, color: SmartSoleColors.biWarning),
                                const SizedBox(width: 4),
                                Text(l.immFatigue, style: textTheme.labelSmall?.copyWith(color: SmartSoleColors.biWarning, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Score IMM Hero
                  GlassBentoCard(
                    accentColor: SmartSoleColors.colorForState(immState),
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    child: Column(
                      children: [
                        Text(immScore.toStringAsFixed(0), style: textTheme.displayLarge?.copyWith(color: SmartSoleColors.colorForState(immState))),
                        const SizedBox(height: 4),
                        Text(l.immMaturityScore, style: textTheme.titleMedium?.copyWith(color: SmartSoleColors.colorForState(immState))),
                        const SizedBox(height: 16),
                        _PercentileBar(percentile: immPercentile),
                        const SizedBox(height: 8),
                        Text('${l.immPercentileFmt} ${immPercentile.toInt()}e — ${_percentileLabel(immPercentile, l)}', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Sous-scores
                  Row(
                    children: [
                      Expanded(child: _SubScoreCard(label: l.immCadence, value: '${cadenceEstimate.toInt()}', unit: l.dashStepsPerMin, icon: Icons.speed, norm: l.immNormCadenceFmt.replaceAll('%d', '${_cadenceNormForAge(childAgeMonths).toInt()}'))),
                      const SizedBox(width: 10),
                      Expanded(child: _SubScoreCard(label: l.immAsymmetry, value: '${asymmetryEstimate.toInt()}%', unit: '', icon: Icons.compare_arrows, norm: l.immNormAsymmetry)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _SubScoreCard(label: l.immDoubleSupport, value: '${doubleSupportPct.toInt()}%', unit: '', icon: Icons.sync_alt, norm: l.immNormDoubleSupport)),
                      const SizedBox(width: 10),
                      Expanded(child: _SubScoreCard(label: l.immVariability, value: '${variabilityCv.toInt()}%', unit: 'CV', icon: Icons.auto_graph, norm: l.immNormVariability)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Évolution IMM
                  GlassBentoCard(
                    padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: const EdgeInsets.only(left: 4), child: Text(l.immEvolution, style: textTheme.titleLarge)),
                        Padding(padding: const EdgeInsets.only(left: 4, top: 2), child: Text('${immHistory.length} ${l.immSessions}', style: textTheme.bodySmall)),
                        const SizedBox(height: 20),
                        SizedBox(height: 180, child: _buildIMMChart(immHistory, isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Coaching enfant
                  NarrativeCard(
                    accentColor: SmartSoleColors.biTeal,
                    narratives: _childNarratives(l, immScore, immPercentile, asymmetryEstimate.toDouble(), fatigueDetected),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _computeImmScore(Session session) {
    // IMM derived from posture + global score
    return (session.postureScore * 0.6 + session.globalScore * 0.4).clamp(0, 100);
  }

  double _computePercentile(double immScore, int ageMonths) {
    // Simplified percentile: higher score = higher percentile
    return (immScore * 1.0).clamp(5, 99);
  }

  double _estimateCadence(Session session) {
    if (session.steps == 0) return 0;
    // Parse duration to estimate cadence
    final parts = session.duration.split(':');
    int totalMinutes = 1;
    if (parts.length == 3) {
      totalMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } else if (parts.length == 2) {
      totalMinutes = int.parse(parts[0]);
    }
    if (totalMinutes <= 0) totalMinutes = 1;
    return session.steps / totalMinutes;
  }

  double _cadenceNormForAge(int ageMonths) {
    if (ageMonths < 24) return 176;
    if (ageMonths < 36) return 154;
    if (ageMonths < 48) return 142;
    if (ageMonths < 60) return 136;
    if (ageMonths < 84) return 128;
    return 120;
  }

  Widget _buildIMMChart(List<double> history, bool isDark) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, drawVerticalLine: false, horizontalInterval: 20,
          getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 20, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: 10, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text('S${v.toInt() + 1}', style: TextStyle(fontSize: 10, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight))))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0, maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i])),
            isCurved: true, curveSmoothness: 0.35, color: SmartSoleColors.biTeal, barWidth: 2.5, isStrokeCapRound: true,
            dotData: FlDotData(show: true, getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(radius: 4, color: SmartSoleColors.biTeal, strokeWidth: 2, strokeColor: isDark ? SmartSoleColors.darkBg : Colors.white)),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [SmartSoleColors.biTeal.withValues(alpha: 0.15), SmartSoleColors.biTeal.withValues(alpha: 0.0)])),
          ),
        ],
      ),
      duration: SmartSoleDesign.animSlow,
      curve: SmartSoleDesign.animCurve,
    );
  }

  String _percentileLabel(double percentile, AppLocalizations l) {
    if (percentile >= 75) return l.immAboveAvg;
    if (percentile >= 50) return l.immAverage;
    if (percentile >= 25) return l.immBelowAvg;
    return l.immFarBelowAvg;
  }

  List<String> _childNarratives(AppLocalizations l, double immScore, double percentile, double asymmetry, bool fatigueDetected) {
    final List<String> phrases = [];
    if (percentile < 25) {
      phrases.add(l.immNarrativeLow);
    }
    if (fatigueDetected) {
      phrases.add(l.immNarrativeFatigue);
    }
    if (asymmetry > 15) {
      phrases.add(l.immNarrativeAsymmetry);
    }
    if (phrases.isEmpty) {
      phrases.add(l.immNarrativeGood);
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
            Container(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
            FractionallySizedBox(
              widthFactor: (percentile / 100).clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [SmartSoleColors.biTeal, SmartSoleColors.biNormal]),
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
  const _SubScoreCard({required this.label, required this.value, required this.unit, required this.icon, required this.norm});
  final String label, value, unit;
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
          Row(children: [
            Icon(icon, size: 14, color: SmartSoleColors.biTeal),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: SmartSoleColors.biTeal)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(unit, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ]),
          const SizedBox(height: 4),
          Text(norm, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight)),
        ],
      ),
    );
  }
}
