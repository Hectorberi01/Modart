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

  int _selectedDuration = 30;

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
              // ── Dernière session ───────────────────────────────────────
              const SizedBox(height: 8),
              _buildLastSessionCard(isDark, textTheme),
              const SizedBox(height: 20),

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

              // ── Répartition des zones de charge ───────────────────────
              GlassBentoCard(
                padding: const EdgeInsets.fromLTRB(12, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 18,
                            color: SmartSoleColors.biTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Répartition des charges',
                            style: textTheme.titleLarge,
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _selectedDuration,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: SmartSoleColors.biTeal,
                              size: 18,
                            ),
                            dropdownColor:
                                isDark
                                    ? SmartSoleColors.darkCard
                                    : SmartSoleColors.lightSurface,
                            underline: const SizedBox(),
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedDuration = newValue;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 7,
                                child: Text('7 sessions'),
                              ),
                              DropdownMenuItem(
                                value: 15,
                                child: Text('15 sessions'),
                              ),
                              DropdownMenuItem(
                                value: 30,
                                child: Text('30 sessions'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_selectedDuration dernières sessions — distribution plantaire',
                      style: textTheme.bodySmall?.copyWith(
                        color:
                            isDark
                                ? SmartSoleColors.textTertiaryDark
                                : SmartSoleColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: _buildZoneDistributionChart(isDark),
                    ),
                    const SizedBox(height: 12),
                    _buildZoneLegend(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dernière session card ──────────────────────────────────────────────

  Widget _buildLastSessionCard(bool isDark, TextTheme textTheme) {
    final features = _mock.thomasSessionFeatures;

    // Score composite (même calcul que SessionSummaryScreen)
    final int score = ((100 - features.hotspotScore) * 0.3 +
            features.rollScoreMean * 0.3 +
            features.stabilityScore * 0.2 +
            (100 - features.asymmetryPct) * 0.2)
        .round();

    final BIState scoreState = score >= 70
        ? BIState.normal
        : score >= 50
            ? BIState.warning
            : BIState.alert;
    final Color scoreColor = SmartSoleColors.colorForState(scoreState);

    return GlassBentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: SmartSoleColors.biTeal,
              ),
              const SizedBox(width: 8),
              Text('Dernière session', style: textTheme.titleMedium),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/summary'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SmartSoleColors.biNormal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Détails',
                        style: TextStyle(
                          fontFamily: 'Articulat CF',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SmartSoleColors.biNormal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: SmartSoleColors.biNormal,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Score + métriques
          Row(
            children: [
              // Score global
              Column(
                children: [
                  Text(
                    score.toString(),
                    style: TextStyle(
                      fontFamily: 'Articulat CF',
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontFamily: 'Articulat CF',
                      fontSize: 10,
                      color: isDark
                          ? SmartSoleColors.textTertiaryDark
                          : SmartSoleColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Séparateur
              Container(
                width: 1,
                height: 48,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 16),
              // KPIs compacts
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniKpi(
                      label: 'Hotspot',
                      value: '${features.hotspotScore.toInt()}',
                      state: features.hotspotScore > 60
                          ? BIState.alert
                          : BIState.normal,
                      isDark: isDark,
                    ),
                    _MiniKpi(
                      label: 'Déroulé',
                      value: '${features.rollScoreMean.toInt()}',
                      state: features.rollScoreMean < 50
                          ? BIState.alert
                          : features.rollScoreMean < 70
                              ? BIState.warning
                              : BIState.normal,
                      isDark: isDark,
                    ),
                    _MiniKpi(
                      label: 'Asym.',
                      value: '${features.asymmetryPct.toInt()}%',
                      state: features.asymmetryPct > 15
                          ? BIState.alert
                          : features.asymmetryPct > 7
                              ? BIState.warning
                              : BIState.normal,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  // ── Zone distribution — stacked proportional bars ───────────────

  Widget _buildZoneDistributionChart(bool isDark) {
    // Genere des données de répartition zone (forefoot/midfoot/heel)
    // à partir de sessions mocknées selon la durée sélectionnée.
    final List<(double ff, double mf, double hl)> data = List.generate(
      _selectedDuration,
      (i) {
        // Thème Thomas : avant-pied souvent surchargé
        final double base = 0.10 + (i / _selectedDuration) * 0.08;
        final double ff = (0.45 + base + (i.isEven ? 0.08 : -0.04)).clamp(
          0.0,
          0.99,
        );
        final double mf = (0.20 - base * 0.5 + (i.isOdd ? 0.04 : -0.02)).clamp(
          0.0,
          0.40,
        );
        final double hl = (1.0 - ff - mf).clamp(0.01, 0.60);
        return (ff, mf, hl);
      },
    );

    // One segment = one bar of the stacked chart
    final List<BarChartGroupData> groups = List.generate(data.length, (i) {
      final (double ff, double mf, double hl) = data[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: 1.0,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            rodStackItems: [
              // Heel (bottom)
              BarChartRodStackItem(
                0,
                hl,
                const Color(0xFF6366F1).withValues(alpha: 0.70),
              ),
              // Midfoot
              BarChartRodStackItem(
                hl,
                hl + mf,
                const Color(0xFF10B981).withValues(alpha: 0.75),
              ),
              // Forefoot (top)
              BarChartRodStackItem(
                hl + mf,
                1.0,
                _forefootColor(ff).withValues(alpha: 0.82),
              ),
            ],
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _selectedDuration > 15 ? 10 : 5,
              getTitlesWidget: (v, _) {
                final int session = v.toInt() + 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'S$session',
                    style: TextStyle(
                      fontSize: 8,
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
        ),
      ),
    );
  }

  /// Couleur de l'avant-pied selon son niveau de charge (standardisé avec la map)
  Color _forefootColor(double v) {
    return SmartSoleColors.getPressureColor(v);
  }

  Widget _buildZoneLegend(bool isDark) {
    final Color textColor =
        isDark
            ? SmartSoleColors.textSecondaryDark
            : SmartSoleColors.textSecondaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(
          color: const Color(0xFFEF4444),
          label: 'Avant-pied',
          textColor: textColor,
        ),
        const SizedBox(width: 16),
        _LegendDot(
          color: const Color(0xFF10B981),
          label: 'Médio',
          textColor: textColor,
        ),
        const SizedBox(width: 16),
        _LegendDot(
          color: const Color(0xFF6366F1),
          label: 'Talon',
          textColor: textColor,
        ),
      ],
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

// ─── Legend Dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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

// ─── Mini KPI (utilisé dans la carte dernière session) ───────────────────────

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    required this.state,
    required this.isDark,
  });

  final String label;
  final String value;
  final BIState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color color = SmartSoleColors.colorForState(state);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Articulat CF',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Articulat CF',
            fontSize: 10,
            color: isDark
                ? SmartSoleColors.textTertiaryDark
                : SmartSoleColors.textTertiaryLight,
          ),
        ),
      ],
    );
  }
}
