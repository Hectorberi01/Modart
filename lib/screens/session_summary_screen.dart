import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/narrative_card.dart';
import '../widgets/mlpi_slider.dart';
import '../models/session_features.dart';
import '../services/mock_data_service.dart';
import '../services/narrative_service.dart';
import 'session_summary_screen_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionSummaryScreen — Le moment "aha"
//
// Score global éditorial + 4 blocs KPI + narration BI coach + slider douleur.
// ─────────────────────────────────────────────────────────────────────────────

class SessionSummaryScreen extends StatefulWidget {
  const SessionSummaryScreen({super.key});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final MockDataService _mock = MockDataService.instance;
  double _painScore = 4;

  late SessionFeatures _features;
  late List<String> _narratives;

  @override
  void initState() {
    super.initState();
    _features = _mock.thomasSessionFeatures;
    _narratives = NarrativeService.instance.generateNarrative(
      features: _features,
      previousRollScore: 57,
      hotspotSessionCount: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Score global composite
    final int globalScore =
        ((100 - _features.hotspotScore) * 0.3 +
                _features.rollScoreMean * 0.3 +
                _features.stabilityScore * 0.2 +
                (100 - _features.asymmetryPct) * 0.2)
            .round();

    final BIState scoreState =
        globalScore >= 70
            ? BIState.normal
            : globalScore >= 50
            ? BIState.warning
            : BIState.alert;

    return MeshGradientBackground(
      biState: scoreState,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Résumé de session', style: textTheme.headlineSmall),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            children: [
              // ── Score Global ────────────────────────────────────────────
              const SizedBox(height: 16),
              Text(
                globalScore.toString(),
                style: textTheme.displayLarge?.copyWith(
                  color: SmartSoleColors.colorForState(scoreState),
                  fontSize: 96,
                ),
              ),
              Text(
                'Score Global',
                style: textTheme.titleMedium?.copyWith(
                  color: SmartSoleColors.colorForState(scoreState),
                ),
              ),
              const SizedBox(height: 6),
              Text(_scoreLabel(globalScore), style: textTheme.bodySmall),
              const SizedBox(height: 24),

              // ── 4 Blocs KPI ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SummaryKpi(
                      label: 'Hotspot',
                      value: '${_features.hotspotScore.toInt()}',
                      unit: '/100',
                      icon: Icons.local_fire_department,
                      biState:
                          _features.hotspotScore > 60
                              ? BIState.alert
                              : BIState.normal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryKpi(
                      label: 'Déroulé',
                      value: '${_features.rollScoreMean.toInt()}',
                      unit: '/100',
                      icon: Icons.trending_up,
                      biState:
                          _features.rollScoreMean < 50
                              ? BIState.alert
                              : _features.rollScoreMean < 70
                              ? BIState.warning
                              : BIState.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SummaryKpi(
                      label: 'Asymétrie',
                      value: '${_features.asymmetryPct.toInt()}%',
                      unit: 'G/D',
                      icon: Icons.compare_arrows,
                      biState:
                          _features.asymmetryPct > 20
                              ? BIState.alert
                              : _features.asymmetryPct > 10
                              ? BIState.warning
                              : BIState.normal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 16,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              const SizedBox(width: 6),
                              Text('MLPI', style: textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          MLPISlider(value: _features.mlpiMean),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Narration BI Coach ─────────────────────────────────────
              NarrativeCard(
                narratives: _narratives,
                accentColor: SmartSoleColors.colorForState(scoreState),
              ),
              const SizedBox(height: 20),

              // ── Recommandations dynamiques ─────────────────────────────
              SessionRecommendations(features: _features),
              const SizedBox(height: 20),

              // ── Slider Douleur Post-Session ────────────────────────────
              GlassBentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Douleur post-session', style: textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(
                      'Comment vous sentez-vous ?',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          _painScore.toInt().toString(),
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 32,
                            color: _painColor(_painScore),
                          ),
                        ),
                        Text('/10', style: textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _painColor(_painScore),
                              thumbColor: _painColor(_painScore),
                              inactiveTrackColor: _painColor(
                                _painScore,
                              ).withValues(alpha: 0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _painScore,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              onChanged: (v) => setState(() => _painScore = v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: export PDF
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Exporter PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : Colors.black54,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SmartSoleDesign.borderRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: share rapport
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent — marche équilibrée';
    if (score >= 60) return 'Correct — quelques points à surveiller';
    if (score >= 40) return 'Vigilance — déséquilibre détecté';
    return 'Alerte — consultation recommandée';
  }

  Color _painColor(double score) {
    if (score <= 3) return SmartSoleColors.biNormal;
    if (score <= 6) return SmartSoleColors.biWarning;
    return SmartSoleColors.biAlert;
  }
}

// ─── Summary KPI Card ─────────────────────────────────────────────────────

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.biState,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final BIState biState;

  @override
  Widget build(BuildContext context) {
    final Color accent = SmartSoleColors.colorForState(biState);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBentoCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 32, color: accent),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
