import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — Première impression SmartSole
//
// Mesh gradient + logo + 3 cartes profil glassmorphism (Urban/Kids/Pro).
// Sélection profil → auth → flow principal.
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  ProfileType? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  void _onProfileSelected(ProfileType type) {
    setState(() => _selectedProfile = type);
  }

  void _onContinue() {
    if (_selectedProfile == null) return;
    // TODO: Navigate to PairingScreen
    Navigator.pushReplacementNamed(context, '/pairing');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return MeshGradientBackground(
      biState: BIState.teal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo + Titre ──────────────────────────────────────────
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // Logo icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              SmartSoleColors.biNormal,
                              SmartSoleColors.biTeal,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: SmartSoleColors.biNormal.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hiking,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'SmartSole',
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comprendre. Prévenir. Agir.',
                        style: textTheme.bodyMedium?.copyWith(
                          color:
                              isDark
                                  ? SmartSoleColors.textSecondaryDark
                                  : SmartSoleColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // ── Sélection profil ──────────────────────────────────────
                Text(
                  'Choisissez votre profil',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                _ProfileCard(
                  type: ProfileType.urban,
                  title: 'Actif Urbain',
                  subtitle: 'Running, marche quotidienne, prévention',
                  icon: Icons.directions_walk,
                  isSelected: _selectedProfile == ProfileType.urban,
                  onTap: () => _onProfileSelected(ProfileType.urban),
                ),
                const SizedBox(height: 10),
                _ProfileCard(
                  type: ProfileType.kids,
                  title: 'Parent — Suivi Enfant',
                  subtitle: 'Développement de la marche, IMM, pédiatrique',
                  icon: Icons.child_care,
                  isSelected: _selectedProfile == ProfileType.kids,
                  onTap: () => _onProfileSelected(ProfileType.kids),
                ),
                const SizedBox(height: 10),
                _ProfileCard(
                  type: ProfileType.pro,
                  title: 'Professionnel Santé',
                  subtitle: 'Diagnostic, rapport PDF, suivi J0→J30',
                  icon: Icons.medical_services_outlined,
                  isSelected: _selectedProfile == ProfileType.pro,
                  onTap: () => _onProfileSelected(ProfileType.pro),
                ),

                const Spacer(),

                // ── CTA Glow Button ──────────────────────────────────────
                AnimatedOpacity(
                  opacity: _selectedProfile != null ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow:
                          _selectedProfile != null
                              ? [
                                BoxShadow(
                                  color: SmartSoleColors.biNormal.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                              : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _selectedProfile != null ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continuer'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final ProfileType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentForType(type);

    return GlassBentoCard(
      onTap: onTap,
      accentColor: isSelected ? accent : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icône
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isSelected
                      ? accent.withValues(alpha: 0.2)
                      : accent.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 12),
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          // Check
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accent : Colors.transparent,
              border: Border.all(
                color: isSelected ? accent : Colors.white24,
                width: 2,
              ),
            ),
            child:
                isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
          ),
        ],
      ),
    );
  }

  Color _accentForType(ProfileType type) {
    return switch (type) {
      ProfileType.urban => SmartSoleColors.biNormal,
      ProfileType.kids => SmartSoleColors.biTeal,
      ProfileType.pro => SmartSoleColors.biNavy,
    };
  }
}
