import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/metric_info_sheet.dart';
import '../providers.dart';
import '../models/session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoryTrendsScreen — Évolution basée sur les vraies sessions SQLite
// ─────────────────────────────────────────────────────────────────────────────

class HistoryTrendsScreen extends ConsumerStatefulWidget {
  const HistoryTrendsScreen({super.key});

  @override
  ConsumerState<HistoryTrendsScreen> createState() => _HistoryTrendsScreenState();
}

class _HistoryTrendsScreenState extends ConsumerState<HistoryTrendsScreen> {
  int _selectedMetric = 0;
  int _selectedDuration = 30;

  static const List<String> _metricLabels = [
    'Score Global',
    'Score Posture',
    'Pas',
  ];

  MetricInfo _metricInfoForIndex(int index) {
    switch (index) {
      case 0:
        return MetricCatalog.hotspot;
      case 1:
        return MetricCatalog.rollScore;
      case 2:
        return MetricCatalog.asymmetry;
      default:
        return MetricCatalog.hotspot;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionsAsync = ref.watch(sessionsProvider);

    return MeshGradientBackground(
      biState: BIState.navy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text('Tendances', style: textTheme.headlineSmall),
          centerTitle: true,
        ),
        body: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: SmartSoleColors.biNormal, strokeWidth: 2)),
          error: (e, _) => Center(child: Text('Erreur: $e', style: textTheme.bodyMedium)),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timeline, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 16),
                    Text('Aucune session enregistrée', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Les tendances apparaîtront après vos premières sessions.', style: textTheme.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            // Use most recent sessions up to _selectedDuration
            final displaySessions = sessions.length > _selectedDuration
                ? sessions.sublist(sessions.length - _selectedDuration)
                : sessions;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sélecteur de métrique
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_metricLabels.length, (i) {
                        final bool selected = _selectedMetric == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMetric = i),
                            child: AnimatedContainer(
                              duration: SmartSoleDesign.animNormal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? SmartSoleColors.biNavy.withValues(alpha: 0.2)
                                    : isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadiusSm),
                                border: Border.all(
                                  color: selected ? SmartSoleColors.biNavy.withValues(alpha: 0.4) : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                _metricLabels[i],
                                style: textTheme.labelLarge?.copyWith(
                                  color: selected ? SmartSoleColors.biNavy : isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Graphique principal
                  GlassBentoCard(
                    padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Text(_metricLabels[_selectedMetric], style: textTheme.titleLarge),
                              const SizedBox(width: 8),
                              MetricInfoButton(metric: _metricInfoForIndex(_selectedMetric)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text('${displaySessions.length} dernières sessions', style: textTheme.bodySmall),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(height: 220, child: _buildChart(displaySessions, isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── KPIs moyennes
                  Row(
                    children: [
                      Expanded(
                        child: _TrendKpi(
                          label: 'Moyenne',
                          value: _avgValue(displaySessions).toStringAsFixed(1),
                          icon: Icons.analytics_outlined,
                          color: SmartSoleColors.biNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TrendKpi(
                          label: 'Tendance',
                          value: _trendArrow(displaySessions),
                          icon: Icons.trending_up,
                          color: _trendColor(displaySessions),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TrendKpi(
                          label: 'Sessions',
                          value: '${displaySessions.length}',
                          icon: Icons.calendar_today_outlined,
                          color: SmartSoleColors.biTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Répartition des scores par session
                  GlassBentoCard(
                    padding: const EdgeInsets.fromLTRB(12, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart_rounded, size: 18, color: SmartSoleColors.biTeal),
                              const SizedBox(width: 8),
                              Text('Score vs Posture', style: textTheme.titleLarge),
                              const Spacer(),
                              DropdownButton<int>(
                                value: _selectedDuration,
                                icon: Icon(Icons.keyboard_arrow_down, color: SmartSoleColors.biTeal, size: 18),
                                dropdownColor: isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
                                underline: const SizedBox(),
                                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                onChanged: (int? newValue) {
                                  if (newValue != null) setState(() => _selectedDuration = newValue);
                                },
                                items: const [
                                  DropdownMenuItem(value: 7, child: Text('7 sessions')),
                                  DropdownMenuItem(value: 15, child: Text('15 sessions')),
                                  DropdownMenuItem(value: 30, child: Text('30 sessions')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${displaySessions.length} sessions — comparaison score global / posture',
                          style: textTheme.bodySmall?.copyWith(
                            color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(height: 120, child: _buildComparisonChart(displaySessions, isDark)),
                        const SizedBox(height: 12),
                        _buildComparisonLegend(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Chart builder ─────────────────────────────────────────────────────

  List<double> _dataForMetric(List<Session> sessions, int index) {
    return switch (index) {
      0 => sessions.map((s) => s.globalScore).toList(),
      1 => sessions.map((s) => s.postureScore).toList(),
      2 => sessions.map((s) => s.steps.toDouble()).toList(),
      _ => [],
    };
  }

  Color _colorForMetric(int index) {
    return switch (index) {
      0 => SmartSoleColors.biNormal,
      1 => SmartSoleColors.biNavy,
      2 => SmartSoleColors.biTeal,
      _ => SmartSoleColors.biNavy,
    };
  }

  Widget _buildChart(List<Session> sessions, bool isDark) {
    final List<double> data = _dataForMetric(sessions, _selectedMetric);
    final Color lineColor = _colorForMetric(_selectedMetric);

    // For steps, use actual range; for scores, use 0-100
    final bool isSteps = _selectedMetric == 2;
    final double maxY = isSteps ? (data.isEmpty ? 100 : (data.reduce((a, b) => a > b ? a : b) * 1.2).clamp(100, 100000)) : 100;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: isSteps ? maxY / 5 : 20,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isSteps ? 44 : 32,
              interval: isSteps ? maxY / 5 : 20,
              getTitlesWidget: (v, _) => Text(
                isSteps ? v.toInt().toString() : v.toInt().toString(),
                style: TextStyle(fontSize: 10, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: data.length > 14 ? 7 : (data.length > 7 ? 3 : 1),
              getTitlesWidget: (v, _) {
                final int idx = v.toInt();
                if (idx < 0 || idx >= sessions.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'S${idx + 1}',
                    style: TextStyle(fontSize: 9, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
            isCurved: true,
            curveSmoothness: 0.3,
            color: lineColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lineColor.withValues(alpha: 0.15), lineColor.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final session = idx < sessions.length ? sessions[idx] : null;
                final label = session != null ? '${session.date}: ' : 'S${idx + 1}: ';
                return LineTooltipItem(
                  '$label${isSteps ? spot.y.toInt().toString() : spot.y.toStringAsFixed(1)}',
                  TextStyle(color: lineColor, fontWeight: FontWeight.w600, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: SmartSoleDesign.animSlow,
      curve: SmartSoleDesign.animCurve,
    );
  }

  // ── Comparison chart (global score vs posture score) ───────────────

  Widget _buildComparisonChart(List<Session> sessions, bool isDark) {
    final List<BarChartGroupData> groups = List.generate(sessions.length, (i) {
      final s = sessions[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: s.globalScore.clamp(0, 100),
            width: 4,
            color: SmartSoleColors.biNormal.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
          BarChartRodData(
            toY: s.postureScore.clamp(0, 100),
            width: 4,
            color: SmartSoleColors.biNavy.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: sessions.length > 15 ? 10 : 5,
              getTitlesWidget: (v, _) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'S${v.toInt() + 1}',
                    style: TextStyle(fontSize: 8, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonLegend(bool isDark) {
    final Color textColor = isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: SmartSoleColors.biNormal, label: 'Score Global', textColor: textColor),
        const SizedBox(width: 16),
        _LegendDot(color: SmartSoleColors.biNavy, label: 'Posture', textColor: textColor),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  double _avgValue(List<Session> sessions) {
    final data = _dataForMetric(sessions, _selectedMetric);
    if (data.isEmpty) return 0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  String _trendArrow(List<Session> sessions) {
    final data = _dataForMetric(sessions, _selectedMetric);
    if (data.length < 4) return '—';
    final int half = data.length ~/ 2;
    final double firstHalf = data.take(half).reduce((a, b) => a + b) / half;
    final double secondHalf = data.skip(half).reduce((a, b) => a + b) / (data.length - half);
    final double diff = secondHalf - firstHalf;
    if (diff.abs() < 2) return '-> Stable';
    return diff > 0 ? '^ +${diff.abs().toStringAsFixed(1)}' : 'v ${diff.toStringAsFixed(1)}';
  }

  Color _trendColor(List<Session> sessions) {
    final data = _dataForMetric(sessions, _selectedMetric);
    if (data.length < 4) return SmartSoleColors.textSecondaryDark;
    final int half = data.length ~/ 2;
    final double firstHalf = data.take(half).reduce((a, b) => a + b) / half;
    final double secondHalf = data.skip(half).reduce((a, b) => a + b) / (data.length - half);
    final double diff = secondHalf - firstHalf;
    // For all metrics, going up is good
    return diff > 2 ? SmartSoleColors.biNormal : diff < -2 ? SmartSoleColors.biAlert : SmartSoleColors.biTeal;
  }
}

// ─── Legend Dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.textColor});
  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Trend KPI Card ────────────────────────────────────────────────────────

class _TrendKpi extends StatelessWidget {
  const _TrendKpi({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBentoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight)),
        ],
      ),
    );
  }
}
