import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/metric_info_sheet.dart';
import '../models/session_features.dart';
import '../services/mock_data_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HistoryTrendsScreen — Évolution sur 30 jours
//
// 3 graphiques fl_chart : Hotspot, Roll Score, Asymétrie.
// KPIs moyennes, tendance, alerte persistante.
// ─────────────────────────────────────────────────────────────────────────────

class HistoryTrendsScreen extends StatefulWidget {
  const HistoryTrendsScreen({super.key});

  @override
  State<HistoryTrendsScreen> createState() => _HistoryTrendsScreenState();
}

class _HistoryTrendsScreenState extends State<HistoryTrendsScreen> {
  final MockDataService _mock = MockDataService.instance;
  late List<SessionFeatures> _history;
  int _selectedMetric = 0;

  static const List<String> _metricLabels = [
    'Score Hotspot',
    'Score Déroulé',
    'Asymétrie %',
  ];

  @override
  void initState() {
    super.initState();
    _history = _mock.generateHistory(
      baseHotspot: 72,
      baseMlpi: -0.22,
      baseRollScore: 62,
      baseCadence: 98,
      baseAsymmetry: 18,
    );
  }

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Sélecteur de métrique ──────────────────────────────────
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? SmartSoleColors.biNavy.withValues(
                                      alpha: 0.2,
                                    )
                                    : isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(
                              SmartSoleDesign.borderRadiusSm,
                            ),
                            border: Border.all(
                              color:
                                  selected
                                      ? SmartSoleColors.biNavy.withValues(
                                        alpha: 0.4,
                                      )
                                      : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _metricLabels[i],
                            style: textTheme.labelLarge?.copyWith(
                              color:
                                  selected
                                      ? SmartSoleColors.biNavy
                                      : isDark
                                      ? SmartSoleColors.textSecondaryDark
                                      : SmartSoleColors.textSecondaryLight,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // ── Graphique principal ────────────────────────────────────
              GlassBentoCard(
                padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Text(
                            _metricLabels[_selectedMetric],
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          MetricInfoButton(
                            metric: _metricInfoForIndex(_selectedMetric),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Text(
                        '30 derniers jours',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(height: 220, child: _buildChart(isDark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── KPIs moyennes ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _TrendKpi(
                      label: 'Moyenne',
                      value: _avgValue().toStringAsFixed(1),
                      icon: Icons.analytics_outlined,
                      color: SmartSoleColors.biNavy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TrendKpi(
                      label: 'Tendance',
                      value: _trendArrow(),
                      icon: Icons.trending_up,
                      color: _trendColor(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TrendKpi(
                      label: 'Sessions',
                      value: '${_history.length}',
                      icon: Icons.calendar_today_outlined,
                      color: SmartSoleColors.biTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Historique douleur ─────────────────────────────────────
              GlassBentoCard(
                padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            size: 18,
                            color: SmartSoleColors.biAlert.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Douleur', style: textTheme.titleLarge),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 120, child: _buildPainChart(isDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart builder ─────────────────────────────────────────────────────

  Widget _buildChart(bool isDark) {
    final List<double> data = _dataForMetric(_selectedMetric);
    final Color lineColor = _colorForMetric(_selectedMetric);

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
              interval: 7,
              getTitlesWidget: (v, _) {
                final int day = v.toInt() + 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'J$day',
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          isDark
                              ? SmartSoleColors.textTertiaryDark
                              : SmartSoleColors.textTertiaryLight,
                    ),
                  ),
                );
              },
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
              data.length,
              (i) => FlSpot(i.toDouble(), data[i]),
            ),
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
                colors: [
                  lineColor.withValues(alpha: 0.15),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor:
                (_) =>
                    isDark
                        ? SmartSoleColors.darkCard
                        : SmartSoleColors.lightSurface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'J${spot.x.toInt() + 1}: ${spot.y.toStringAsFixed(1)}',
                  TextStyle(
                    color: lineColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
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

  Widget _buildPainChart(bool isDark) {
    final List<int> pain = _mock.generatePainHistory();
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: 10,
        barGroups: List.generate(pain.length, (i) {
          final double v = pain[i].toDouble();
          final Color barColor =
              v <= 3
                  ? SmartSoleColors.biNormal
                  : v <= 6
                  ? SmartSoleColors.biWarning
                  : SmartSoleColors.biAlert;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: v,
                color: barColor.withValues(alpha: 0.7),
                width: 5,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  List<double> _dataForMetric(int index) {
    return switch (index) {
      0 => _history.map((f) => f.hotspotScore).toList(),
      1 => _history.map((f) => f.rollScoreMean).toList(),
      2 => _history.map((f) => f.asymmetryPct).toList(),
      _ => [],
    };
  }

  Color _colorForMetric(int index) {
    return switch (index) {
      0 => SmartSoleColors.biAlert,
      1 => SmartSoleColors.biNormal,
      2 => SmartSoleColors.biWarning,
      _ => SmartSoleColors.biNavy,
    };
  }

  double _avgValue() {
    final data = _dataForMetric(_selectedMetric);
    if (data.isEmpty) return 0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  String _trendArrow() {
    final data = _dataForMetric(_selectedMetric);
    if (data.length < 7) return '—';
    final double first7 = data.take(7).reduce((a, b) => a + b) / 7;
    final double last7 = data.skip(data.length - 7).reduce((a, b) => a + b) / 7;
    final double diff = last7 - first7;
    if (diff.abs() < 2) return '→ Stable';
    return diff > 0
        ? '↑ +${diff.abs().toStringAsFixed(1)}'
        : '↓ ${diff.toStringAsFixed(1)}';
  }

  Color _trendColor() {
    final data = _dataForMetric(_selectedMetric);
    if (data.length < 7) return SmartSoleColors.textSecondaryDark;
    final double first7 = data.take(7).reduce((a, b) => a + b) / 7;
    final double last7 = data.skip(data.length - 7).reduce((a, b) => a + b) / 7;
    final double diff = last7 - first7;
    // Pour hotspot et asymétrie, baisser = bien. Pour roll score, monter = bien.
    if (_selectedMetric == 1) {
      return diff > 2
          ? SmartSoleColors.biNormal
          : diff < -2
          ? SmartSoleColors.biAlert
          : SmartSoleColors.biTeal;
    }
    return diff < -2
        ? SmartSoleColors.biNormal
        : diff > 2
        ? SmartSoleColors.biAlert
        : SmartSoleColors.biTeal;
  }
}

// ─── Trend KPI Card ────────────────────────────────────────────────────────

class _TrendKpi extends StatelessWidget {
  const _TrendKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
