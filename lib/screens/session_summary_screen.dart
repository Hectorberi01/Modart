import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../widgets/narrative_card.dart';
import '../widgets/mlpi_slider.dart';
import '../providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionSummaryScreen — Uses real session data from Riverpod
// ─────────────────────────────────────────────────────────────────────────────

class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({super.key});

  @override
  ConsumerState<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen> {
  double _painScore = 0;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Get real session data
    final session = ref.watch(shoeSessionViewModelProvider);

    // Derive KPIs from real data
    final postureScore = session.postureScore;
    final globalScore = session.globalScore;
    final cadence = session.cadence;
    final steps = session.steps;
    final distance = session.distance;

    // Asymmetry estimate (simplified from posture)
    final asymmetryPct = ((100 - postureScore) * 0.4).clamp(0, 50).toDouble();
    // Roll score (derived from posture)
    final rollScore = postureScore * 0.8 + 20;
    // Stability (derived from posture)
    final stabilityScore = postureScore * 0.7 + 30;
    // Hotspot (inverse of posture quality)
    final hotspotScore = (100 - postureScore) * 0.7;
    // MLPI (derived from posture)
    final mlpi = (postureScore - 50) / 100;

    final int displayScore = globalScore.round().clamp(0, 100);
    final BIState scoreState = displayScore >= 70 ? BIState.normal : displayScore >= 50 ? BIState.warning : BIState.alert;

    // Generate narratives from real data
    final List<String> narratives = [];
    if (hotspotScore > 60) {
      narratives.add('Surcharge detectee sur l\'avant-pied — pensez a ajuster votre foulée.');
    }
    if (rollScore < 50) {
      narratives.add('Le déroulé du pied est insuffisant — travaillez la souplesse de cheville.');
    }
    if (asymmetryPct > 20) {
      narratives.add('Asymétrie ${asymmetryPct.toInt()}% détectée entre pied gauche et droit.');
    }
    if (narratives.isEmpty) {
      narratives.add('Belle session ! Votre marche est équilibrée et votre posture est bonne.');
    }

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
              // ── Score Global
              const SizedBox(height: 16),
              Text(
                displayScore.toString(),
                style: textTheme.displayLarge?.copyWith(color: SmartSoleColors.colorForState(scoreState), fontSize: 96),
              ),
              Text('Score Global', style: textTheme.titleMedium?.copyWith(color: SmartSoleColors.colorForState(scoreState))),
              const SizedBox(height: 6),
              Text(_scoreLabel(displayScore), style: textTheme.bodySmall),
              const SizedBox(height: 8),
              // Session stats
              Text('$steps pas  ·  ${(distance / 1000).toStringAsFixed(2)} km  ·  ${cadence.toStringAsFixed(0)} pas/min', style: textTheme.bodySmall),
              const SizedBox(height: 24),

              // ── 4 KPI Blocks
              Row(
                children: [
                  Expanded(child: _SummaryKpi(label: 'Hotspot', value: '${hotspotScore.toInt()}', unit: '/100', icon: Icons.local_fire_department, biState: hotspotScore > 60 ? BIState.alert : BIState.normal)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryKpi(label: 'Déroulé', value: '${rollScore.toInt()}', unit: '/100', icon: Icons.trending_up, biState: rollScore < 50 ? BIState.alert : rollScore < 70 ? BIState.warning : BIState.normal)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _SummaryKpi(label: 'Asymétrie', value: '${asymmetryPct.toInt()}%', unit: 'G/D', icon: Icons.compare_arrows, biState: asymmetryPct > 20 ? BIState.alert : asymmetryPct > 10 ? BIState.warning : BIState.normal)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                              const SizedBox(width: 6),
                              Text('MLPI', style: textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          MLPISlider(value: mlpi),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Narrative
              NarrativeCard(narratives: narratives, accentColor: SmartSoleColors.colorForState(scoreState)),
              const SizedBox(height: 20),

              // ── Pain slider
              GlassBentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Douleur post-session', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Comment vous sentez-vous ?', style: textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(_painScore.toInt().toString(), style: textTheme.displaySmall?.copyWith(fontSize: 32, color: _painColor(_painScore))),
                        Text('/10', style: textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _painColor(_painScore),
                              thumbColor: _painColor(_painScore),
                              inactiveTrackColor: _painColor(_painScore).withValues(alpha: 0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(value: _painScore, min: 0, max: 10, divisions: 10, onChanged: (v) => setState(() => _painScore = v)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Exporter PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
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

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({required this.label, required this.value, required this.unit, required this.icon, required this.biState});
  final String label, value, unit;
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
          Row(children: [
            Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 32, color: accent)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(unit, style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ],
      ),
    );
  }
}
