import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen — Écran de démarrage SmartSole
//
// Fond dégradé biNormal → biTeal avec le logo SVG blanc centré.
// Durée 2.5 s puis callback onFinished.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2600), widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SmartSoleColors.darkBg,
              Color(0xFF111827),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Logo principal ─────────────────────────────────
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                SmartSoleColors.biNormal,
                                SmartSoleColors.biWarning,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SmartSoleColors.biNormal.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 40,
                                spreadRadius: 4,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SvgPicture.asset(
                              'assets/images/Logo_Blanc.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // ── Nom de l'app ───────────────────────────────────
                        Text(
                          'SmartSole',
                          style: TextStyle(
                            fontFamily: 'Articulat CF',
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: SmartSoleColors.textPrimaryDark,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyse biomécanique intelligente',
                          style: TextStyle(
                            fontFamily: 'Articulat CF',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: SmartSoleColors.textSecondaryDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 52),
                        _PulsingDots(),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Tagline bas de page ────────────────────────────────────
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'TECHNOLOGIE · PERFORMANCE · PRÉCISION',
                    style: TextStyle(
                      fontFamily: 'Articulat CF',
                      color: SmartSoleColors.textTertiaryDark,
                      fontSize: 10,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dots de chargement animés ──────────────────────────────────────────────

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = ((_ctrl.value - i * 0.25) % 1.0).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (1 - (t * 2 - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: SmartSoleColors.biNormal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
