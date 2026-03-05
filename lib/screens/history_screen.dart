import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/l10n/app_localizations.dart';
import 'package:modar/providers.dart';
import '../models/session.dart';

const _kAccent = Color(0xFF2F80ED);
const _kSuccess = Color(0xFF27AE60);

List<BoxShadow> _cardShadow(BuildContext context) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.historyTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _cardShadow(context),
            ),
            child: IconButton(
              onPressed: () => ref.invalidate(sessionsProvider),
              icon: Icon(Icons.refresh_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text('${l.historyError}$e',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
        ),
        data: (sessions) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SummaryCard(sessions: sessions),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (sessions.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: _SessionList(sessions: sessions),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.sessions});
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              icon: Icons.directions_walk_rounded,
              value: '${sessions.length}',
              label: l.historySessions,
              color: _kAccent,
            ),
          ),
          Container(
              width: 1, height: 40, color: theme.colorScheme.outline),
          Expanded(
            child: _SummaryStat(
              icon: Icons.route_rounded,
              value: totalDistanceKm.toStringAsFixed(1),
              label: l.historyKmTotal,
              color: _kSuccess,
            ),
          ),
          Container(
              width: 1, height: 40, color: theme.colorScheme.outline),
          Expanded(
            child: _SummaryStat(
              icon: Icons.directions_walk_rounded,
              value: totalSteps >= 1000
                  ? '${(totalSteps / 1000).toStringAsFixed(1)}k'
                  : '$totalSteps',
              label: l.historyStepsTotal,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(context),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sessions.length; i++) ...[
            _SessionRow(session: sessions[i]),
            if (i < sessions.length - 1)
              Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: theme.colorScheme.outline),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});
  final Session session;

  Color get _scoreColor {
    if (session.globalScore >= 70) return _kSuccess;
    if (session.globalScore >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEB5757);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_walk_rounded,
                color: _kAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.date}  ·  ${session.time}  ·  ${session.duration}',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.steps} pas  ·  ${session.distance}',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${session.globalScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.avgSpeed,
                style: TextStyle(
                    fontSize: 11,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: _cardShadow(context),
            ),
            child: Icon(Icons.history_rounded,
                size: 36,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            l.historyNoSession,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            l.historyNoSessionDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
