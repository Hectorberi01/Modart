import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_bento_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NarrativeCard v2 — Coach BI textuel
//
// Card glassmorphism avec icône coaching, 2 phrases narratives animées
// en fondu séquentiel, accent dynamique BI.
// ─────────────────────────────────────────────────────────────────────────────

class NarrativeCard extends StatefulWidget {
  const NarrativeCard({super.key, required this.narratives, this.accentColor});

  final List<String> narratives;
  final Color? accentColor;

  @override
  State<NarrativeCard> createState() => _NarrativeCardState();
}

class _NarrativeCardState extends State<NarrativeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade1;
  late Animation<double> _fade2;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade1 = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _fade2 = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void didUpdateWidget(NarrativeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.narratives != widget.narratives) {
      _fadeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = widget.accentColor ?? SmartSoleColors.biNormal;

    return GlassBentoCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.auto_awesome, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                'Coach SmartSole',
                style: textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Phrases narratives avec animation
          ...List.generate(widget.narratives.length, (i) {
            final Animation<double> fade = i == 0 ? _fade1 : _fade2;
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(fade),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i < widget.narratives.length - 1 ? 10 : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.narratives[i],
                          style: textTheme.bodyMedium?.copyWith(
                            color:
                                isDark
                                    ? SmartSoleColors.textPrimaryDark
                                        .withValues(alpha: 0.85)
                                    : SmartSoleColors.textPrimaryLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
