import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroScale;
  late Animation<double> _heroOpacity;
  late PageController _pageController;
  int _currentPage = 0;
  ProfileType? _selectedProfile;

  static const int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _heroScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack),
    );
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _heroController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _onProfileSelected(ProfileType type) =>
      setState(() => _selectedProfile = type);

  bool get _canContinue {
    if (_currentPage < _totalPages - 1) return true;
    return _selectedProfile != null;
  }

  void _onContinue() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    if (_selectedProfile == null) return;
    _navigateToRegister();
  }

  void _navigateToRegister() {
    final profile = UserProfile(
      email: '',
      profileType: _selectedProfile!,
      childProfile:
          _selectedProfile == ProfileType.kids
              ? const ChildProfile(nickname: '', birthMonth: 1, birthYear: 2019)
              : null,
    );
    Navigator.pushNamed(context, '/register', arguments: profile);
  }

  void _navigateToLogin() {
    final profile = UserProfile(
      email: '',
      profileType: _selectedProfile ?? ProfileType.urban,
    );
    Navigator.pushNamed(context, '/auth', arguments: profile);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: SmartSoleColors.darkBg,
      body: Stack(
        children: [
          // Mesh background glow
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SmartSoleColors.biNormal.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    SmartSoleColors.biNavy.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // -- PageView
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Page 1
                        _buildSlidePage1(context, isDark, textTheme),
                        // Page 2
                        _buildSlidePage2(context, isDark, textTheme),
                        // Page 3
                        _buildProfileSelectionSlide(context, isDark, textTheme),
                      ],
                    ),
                  ),

                  // -- Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == i
                                  ? SmartSoleColors.biNormal
                                  : Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- Main button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _canContinue ? 1.0 : 0.4,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: SmartSoleColors.heroGradient,
                        boxShadow:
                            _canContinue
                                ? [
                                  BoxShadow(
                                    color: SmartSoleColors.biNormal.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                                : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _canContinue ? _onContinue : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _totalPages - 1
                                    ? AppLocalizations.of(context).onboardingCreateAccount
                                    : AppLocalizations.of(context).onboardingNext,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _totalPages - 1
                                    ? Icons.person_add_outlined
                                    : Icons.arrow_forward,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -- Login link
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context).onboardingAlreadyAccount,
                        style: TextStyle(
                          fontSize: 14,
                          color: SmartSoleColors.textSecondaryDark.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: SmartSoleColors.biTeal,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          AppLocalizations.of(context).onboardingSignIn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SmartSoleColors.biTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Page 1 : biomecanique au quotidien

  Widget _buildSlidePage1(
    BuildContext context,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Illustration
        AnimatedBuilder(
          animation: _heroController,
          builder:
              (context, child) => Opacity(
                opacity: _heroOpacity.value,
                child: Transform.scale(scale: _heroScale.value, child: child),
              ),
          child: Image.asset(
            'assets/images/logo.png',
            height: 220,
            width: 280,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 48),

        // Title
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => SmartSoleColors.heroGradient.createShader(bounds),
          child: Text(
            'Smartsole',
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle
        Text(
          AppLocalizations.of(context).onboardingBiomechanics,
          style: textTheme.titleMedium?.copyWith(
            color: SmartSoleColors.biTeal,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Description
        Text(
          AppLocalizations.of(context).onboardingBiomechanicsDesc,
          style: textTheme.bodyLarge?.copyWith(
            color: SmartSoleColors.textSecondaryDark,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -- Page 2 : donnees actionnables

  Widget _buildSlidePage2(
    BuildContext context,
    bool isDark,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Illustration
        SizedBox(
          width: 280,
          height: 240,
          child: Center(
            child: SvgPicture.asset(
              'assets/images/walk_nature.svg',
              height: 520,
              width: 480,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Title
        Text(
          AppLocalizations.of(context).onboardingWalkConscious,
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: SmartSoleColors.textPrimaryDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // Subtitle
        Text(
          AppLocalizations.of(context).onboardingWalkConsciousSub,
          style: textTheme.titleMedium?.copyWith(
            color: SmartSoleColors.biTeal,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Description
        Text(
          AppLocalizations.of(context).onboardingWalkConsciousDesc,
          style: textTheme.bodyLarge?.copyWith(
            color: SmartSoleColors.textSecondaryDark,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -- Page 3 : selection du profil

  Widget _buildProfileSelectionSlide(
    BuildContext context,
    bool isDark,
    TextTheme textTheme,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            AppLocalizations.of(context).onboardingSelectProfile,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: SmartSoleColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).onboardingSelectProfileSub,
            style: textTheme.bodyMedium?.copyWith(
              color: SmartSoleColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 32),

          // Profile cards
          _ProfileCard(
            type: ProfileType.urban,
            title: AppLocalizations.of(context).onboardingUrbanTitle,
            subtitle: AppLocalizations.of(context).onboardingUrbanSub,
            icon: Icons.directions_walk,
            accent: SmartSoleColors.biNormal,
            isSelected: _selectedProfile == ProfileType.urban,
            onTap: () => _onProfileSelected(ProfileType.urban),
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            type: ProfileType.kids,
            title: AppLocalizations.of(context).onboardingKidsTitle,
            subtitle: AppLocalizations.of(context).onboardingKidsSub,
            icon: Icons.child_care,
            accent: SmartSoleColors.biTeal,
            isSelected: _selectedProfile == ProfileType.kids,
            onTap: () => _onProfileSelected(ProfileType.kids),
          ),
          const SizedBox(height: 12),
          _ProfileCard(
            type: ProfileType.pro,
            title: AppLocalizations.of(context).onboardingProTitle,
            subtitle: AppLocalizations.of(context).onboardingProSub,
            icon: Icons.medical_services_outlined,
            accent: SmartSoleColors.biNavy,
            isSelected: _selectedProfile == ProfileType.pro,
            onTap: () => _onProfileSelected(ProfileType.pro),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// -- Profile Card (glass inline)

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  final ProfileType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
        color:
            isSelected
                ? accent.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color:
              isSelected
                  ? accent.withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.10),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Icon with colored background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? accent.withValues(alpha: 0.22)
                            : accent.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 14),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected
                                  ? Colors.white
                                  : SmartSoleColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SmartSoleColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accent : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected
                              ? accent
                              : Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
