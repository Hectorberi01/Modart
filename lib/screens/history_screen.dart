import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/l10n/app_localizations.dart';
import 'package:modar/providers.dart';
import '../models/session.dart';

const _kPrimary = Color(0xFF1C1F2E);
const _kAccent = Color(0xFF2F80ED);
const _kSuccess = Color(0xFF27AE60);
const _kBg = Color(0xFFF7F8FA);
const _kTextSecondary = Color(0xFF6B7280);

List<BoxShadow> _cardShadow() => [
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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: Text(
          l.historyTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _cardShadow(),
            ),
            child: IconButton(
              onPressed: () => ref.invalidate(sessionsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 20, color: _kPrimary),
            ),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Text('${l.historyError}$e', style: const TextStyle(color: _kTextSecondary)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(),
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
          Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _SummaryStat(
              icon: Icons.route_rounded,
              value: totalDistanceKm.toStringAsFixed(1),
              label: l.historyKmTotal,
              color: _kSuccess,
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
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
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
      ],
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow(),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sessions.length; i++) ...[
            _SessionRow(session: sessions[i]),
            if (i < sessions.length - 1)
              const Divider(height: 1, indent: 72, endIndent: 16, color: Color(0xFFF3F4F6)),
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
            child: const Icon(Icons.directions_walk_rounded, color: _kAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.date}  ·  ${session.time}  ·  ${session.duration}',
                  style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.steps} pas  ·  ${session.distance}',
                  style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${session.globalScore.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _scoreColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.avgSpeed,
                style: const TextStyle(fontSize: 11, color: _kTextSecondary),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD1D5DB)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: _cardShadow(),
            ),
            child: const Icon(Icons.history_rounded, size: 36, color: Color(0xFFD1D5DB)),
          ),
          const SizedBox(height: 20),
          Text(
            l.historyNoSession,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            l.historyNoSessionDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }
}
