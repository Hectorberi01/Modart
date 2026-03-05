import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../models/session.dart';
import '../providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProDashboardScreen — Espace Professionnel (données réelles)
//
// Affiche les vraies sessions enregistrées comme "patients" avec leurs scores.
// ─────────────────────────────────────────────────────────────────────────────

class ProDashboardScreen extends ConsumerWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionsAsync = ref.watch(sessionsProvider);

    return MeshGradientBackground(
      biState: BIState.navy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Espace Professionnel', style: textTheme.headlineMedium),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassBentoCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.medical_services, color: SmartSoleColors.biNavy),
                        const SizedBox(width: 8),
                        Text('Outils de suivi', style: textTheme.titleLarge!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Retrouvez ici les sessions enregistrées et leurs analyses biomécaniques.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Stats summary
              sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: SmartSoleColors.biNavy, strokeWidth: 2)),
                error: (e, _) => Text('Erreur: $e'),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return GlassBentoCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.folder_open, size: 40, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            Text('Aucune session enregistrée', style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('Les sessions apparaîtront ici après enregistrement.', style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  }

                  // Compute aggregate stats
                  final avgScore = sessions.map((s) => s.globalScore).reduce((a, b) => a + b) / sessions.length;
                  final avgPosture = sessions.map((s) => s.postureScore).reduce((a, b) => a + b) / sessions.length;
                  final totalSteps = sessions.fold<int>(0, (sum, s) => sum + s.steps);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary KPIs
                      Row(
                        children: [
                          Expanded(child: _ProKpi(label: 'Score moyen', value: '${avgScore.toStringAsFixed(0)}%', icon: Icons.analytics, color: SmartSoleColors.biNormal)),
                          const SizedBox(width: 10),
                          Expanded(child: _ProKpi(label: 'Posture moy.', value: '${avgPosture.toStringAsFixed(0)}%', icon: Icons.accessibility_new, color: SmartSoleColors.biNavy)),
                          const SizedBox(width: 10),
                          Expanded(child: _ProKpi(label: 'Total pas', value: totalSteps >= 1000 ? '${(totalSteps / 1000).toStringAsFixed(1)}k' : '$totalSteps', icon: Icons.directions_walk, color: SmartSoleColors.biTeal)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text('Sessions récentes', style: textTheme.headlineSmall!),
                      const SizedBox(height: 12),

                      // Recent sessions as "patient" cards
                      ...sessions.reversed.take(10).map((session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSessionCard(context, session, isDark),
                      )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Session session, bool isDark) {
    final scoreColor = session.globalScore >= 70
        ? SmartSoleColors.biSuccess
        : session.globalScore >= 40
            ? SmartSoleColors.biWarning
            : SmartSoleColors.biAlert;

    return GlassBentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SmartSoleColors.biNavy.withValues(alpha: 0.15),
            foregroundColor: SmartSoleColors.biNavy,
            child: const Icon(Icons.directions_walk, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${session.date}  ·  ${session.time}  ·  ${session.duration}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.steps} pas  ·  ${session.distance}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${session.globalScore.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scoreColor)),
              ),
              const SizedBox(height: 4),
              Text('Posture: ${session.postureScore.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight,
              )),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black54),
        ],
      ),
    );
  }
}

class _ProKpi extends StatelessWidget {
  const _ProKpi({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassBentoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
