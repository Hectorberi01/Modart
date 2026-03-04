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
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late PageController _pageController;
  int _currentPage = 0;

  ProfileType? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    _pageController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _onProfileSelected(ProfileType type) {
    setState(() => _selectedProfile = type);
  }

  void _onContinue() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    if (_selectedProfile == null) return;

    // Build a minimal mock UserProfile matching the chosen type,
    // so AuthScreen can personalise its greeting.
    final profile = UserProfile(
      email: switch (_selectedProfile!) {
        ProfileType.urban => 'thomas@smartsole.io',
        ProfileType.kids => 'parent@smartsole.io',
        ProfileType.pro => 'dr.amara@cabinet.fr',
      },
      profileType: _selectedProfile!,
      displayName: switch (_selectedProfile!) {
        ProfileType.urban => 'Thomas',
        ProfileType.kids => 'Marie',
        ProfileType.pro => 'Dr. Amara',
      },
      childProfile:
          _selectedProfile == ProfileType.kids
              ? const ChildProfile(
                nickname: 'Lucas',
                birthMonth: 3,
                birthYear: 2018,
              )
              : null,
    );

    // Navigate to auth screen — it will redirect to /home on success.
    Navigator.pushReplacementNamed(context, '/auth', arguments: profile);
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
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // --- Page 1 : Vision & Valeur ---
                      _buildValuePropSlide(
                        context,
                        isDark,
                        icon: Icons.hiking,
                        title: 'SmartSole',
                        subtitle: 'La biomécanique dans votre quotidien',
                        desc:
                            'Une chaussure connectée qui rend visible la pression et la marche. '
                            'Comprendre, prévenir, agir.',
                      ),
                      // --- Page 2 : BI & Data ---
                      _buildValuePropSlide(
                        context,
                        isDark,
                        icon: Icons.insights_rounded,
                        title: 'Business Intelligence',
                        subtitle: 'Des données claires et actionnables',
                        desc:
                            'Visualisez vos appuis, identifiez vos hotspots et suivez '
                            'l\'évolution de votre démarche.',
                      ),
                      // --- Page 3 : Profil ---
                      _buildProfileSelectionSlide(context, isDark, textTheme),
                    ],
                  ),
                ),

                // ── Indicateurs de pages ────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index
                                ? SmartSoleColors.biNormal
                                : (isDark ? Colors.white24 : Colors.black26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Bouton Continuer ──────────────────────────────────────
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity:
                      (_currentPage < 2 || _selectedProfile != null)
                          ? 1.0
                          : 0.4,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow:
                          (_currentPage < 2 || _selectedProfile != null)
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
                      onPressed:
                          (_currentPage < 2 || _selectedProfile != null)
                              ? _onContinue
                              : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2
                                ? 'Démarrer l\'expérience'
                                : 'Suivant',
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // SLIDE 1 & 2 : VALUE PROP
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildValuePropSlide(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String desc,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Opacity(
              opacity: _logoOpacity.value,
              child: Transform.scale(scale: _logoScale.value, child: child),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SmartSoleColors.biNormal, SmartSoleColors.biTeal],
              ),
              boxShadow: [
                BoxShadow(
                  color: SmartSoleColors.biNormal.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          title,
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: textTheme.titleMedium?.copyWith(
            color: SmartSoleColors.biTeal,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          desc,
          style: textTheme.bodyLarge?.copyWith(
            color:
                isDark
                    ? SmartSoleColors.textSecondaryDark
                    : SmartSoleColors.textSecondaryLight,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // SLIDE 3 : PROFILE SELECTION
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildProfileSelectionSlide(
    BuildContext context,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Choisissez votre profil',
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _ProfileCard(
          type: ProfileType.urban,
          title: 'Actif Urbain',
          subtitle: 'Running, marche quotidienne, prévention',
          icon: Icons.directions_walk,
          isSelected: _selectedProfile == ProfileType.urban,
          onTap: () => _onProfileSelected(ProfileType.urban),
        ),
        const SizedBox(height: 12),
        _ProfileCard(
          type: ProfileType.kids,
          title: 'Parent — Suivi Enfant',
          subtitle: 'Développement de la marche, IMM, pédiatrique',
          icon: Icons.child_care,
          isSelected: _selectedProfile == ProfileType.kids,
          onTap: () => _onProfileSelected(ProfileType.kids),
        ),
        const SizedBox(height: 12),
        _ProfileCard(
          type: ProfileType.pro,
          title: 'Professionnel Santé',
          subtitle: 'Diagnostic, rapport PDF, suivi patient J0→J30',
          icon: Icons.medical_services_outlined,
          isSelected: _selectedProfile == ProfileType.pro,
          onTap: () => _onProfileSelected(ProfileType.pro),
        ),
      ],
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
