import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/l10n/app_localizations.dart';
import 'package:modar/providers.dart';
import 'package:modar/theme/app_theme.dart';
import '../models/session.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sessionsAsync = ref.watch(sessionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? SmartSoleColors.darkBg : SmartSoleColors.lightBg;
    final cardBg = isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface;
    final textPrimary = isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight;
    final textSecondary = isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight;
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(l.historyTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(color: SmartSoleColors.glassBorderDark, width: 0.5) : null,
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: IconButton(
              onPressed: () => ref.invalidate(sessionsProvider),
              icon: Icon(Icons.refresh_rounded, size: 20, color: textPrimary),
            ),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SmartSoleColors.biNormal, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('${l.historyError}$e', style: TextStyle(color: textSecondary))),
        data: (sessions) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SummaryCard(sessions: sessions, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary, isDark: isDark),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (sessions.isEmpty)
              SliverFillRemaining(child: _EmptyState(cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary, isDark: isDark))
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: _SessionList(sessions: sessions, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary, dividerColor: dividerColor, isDark: isDark),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.sessions, required this.cardBg, required this.textPrimary, required this.textSecondary, required this.isDark});
  final List<Session> sessions;
  final Color cardBg, textPrimary, textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    double totalDistanceKm = 0;
    int totalSteps = 0;
    for (final s in sessions) {
      final parts = s.distance.split(' ');
      totalDistanceKm += double.tryParse(parts[0]) ?? 0;
      totalSteps += s.steps;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: SmartSoleColors.glassBorderDark, width: 0.5) : null,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryStat(icon: Icons.directions_walk_rounded, value: '${sessions.length}', label: l.historySessions, color: SmartSoleColors.biNavy, textPrimary: textPrimary, textSecondary: textSecondary)),
          Container(width: 1, height: 40, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB)),
          Expanded(child: _SummaryStat(icon: Icons.route_rounded, value: totalDistanceKm.toStringAsFixed(1), label: l.historyKmTotal, color: SmartSoleColors.biSuccess, textPrimary: textPrimary, textSecondary: textSecondary)),
          Container(width: 1, height: 40, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB)),
          Expanded(child: _SummaryStat(icon: Icons.directions_walk_rounded, value: totalSteps >= 1000 ? '${(totalSteps / 1000).toStringAsFixed(1)}k' : '$totalSteps', label: l.historyStepsTotal, color: SmartSoleColors.biAlert, textPrimary: textPrimary, textSecondary: textSecondary)),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.icon, required this.value, required this.label, required this.color, required this.textPrimary, required this.textSecondary});
  final IconData icon;
  final String value, label;
  final Color color, textPrimary, textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
      ],
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions, required this.cardBg, required this.textPrimary, required this.textSecondary, required this.dividerColor, required this.isDark});
  final List<Session> sessions;
  final Color cardBg, textPrimary, textSecondary, dividerColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: SmartSoleColors.glassBorderDark, width: 0.5) : null,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < sessions.length; i++) ...[
            _SessionRow(session: sessions[i], textPrimary: textPrimary, textSecondary: textSecondary),
            if (i < sessions.length - 1) Divider(height: 1, indent: 72, endIndent: 16, color: dividerColor),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.textPrimary, required this.textSecondary});
  final Session session;
  final Color textPrimary, textSecondary;

  Color get _scoreColor {
    if (session.globalScore >= 70) return SmartSoleColors.biSuccess;
    if (session.globalScore >= 40) return SmartSoleColors.biAlert;
    return const Color(0xFFEB5757);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: SmartSoleColors.biNavy.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.directions_walk_rounded, color: SmartSoleColors.biNavy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
                const SizedBox(height: 3),
                Text('${session.date}  ·  ${session.time}  ·  ${session.duration}', style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 4),
                Text('${session.steps} pas  ·  ${session.distance}', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _scoreColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${session.globalScore.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _scoreColor)),
              ),
              const SizedBox(height: 4),
              Text(session.avgSpeed, style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cardBg, required this.textPrimary, required this.textSecondary, required this.isDark});
  final Color cardBg, textPrimary, textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: isDark ? Border.all(color: SmartSoleColors.glassBorderDark, width: 0.5) : null,
            ),
            child: Icon(Icons.history_rounded, size: 36, color: textSecondary),
          ),
          const SizedBox(height: 20),
          Text(l.historyNoSession, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 6),
          Text(l.historyNoSessionDesc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: textSecondary)),
        ],
      ),
    );
  }
}
