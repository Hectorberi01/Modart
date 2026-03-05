import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RegistrationJourneyScreen — Parcours d'inscription multi-etapes
//
// Recoit un UserProfile avec profileType deja renseigne.
// Gere 3 parcours : Urban (7 etapes), Kids (9 etapes), Pro (6 etapes).
// Animation slide horizontal entre etapes.
// Soumission Firebase sur l'avant-derniere etape (RGPD).
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationJourneyScreen extends ConsumerStatefulWidget {
  const RegistrationJourneyScreen({super.key, required this.initialProfile});

  final UserProfile initialProfile;

  @override
  ConsumerState<RegistrationJourneyScreen> createState() =>
      _RegistrationJourneyScreenState();
}

class _RegistrationJourneyScreenState extends ConsumerState<RegistrationJourneyScreen>
    with TickerProviderStateMixin {
  // -- State

  late UserProfile _profile;
  int _stepIndex = 0;

  // Animation
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // Champs communs
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscurePass = true;

  // Biometrie
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  double? _shoeSize;

  // Genre
  UserGender? _gender;

  // Consentements
  bool _consentCloud = false;
  bool _consentAnalytics = false;
  bool _consentPush = false;

  // PRO — code cabinet
  final _cabinetCodeCtrl = TextEditingController();
  bool _isCabinetCodeValid = false;
  bool _isVerifyingCode = false;

  // KIDS — PIN
  final List<String> _pin = ['', '', '', ''];
  int _pinCursor = 0;
  final List<String> _pinConfirm = ['', '', '', ''];
  int _pinConfirmCursor = 0;
  bool _pinConfirmMode = false;
  String? _pinError;

  // KIDS — infos enfant
  final _childNicknameCtrl = TextEditingController();
  int? _childBirthMonth;
  int? _childBirthYear;
  double? _childShoeSize;

  // Form keys par etape
  final Map<int, GlobalKey<FormState>> _formKeys = {};

  // Succes anime
  bool _showSuccessCheck = false;

  // -- Computed

  ProfileType get _type => _profile.profileType;

  int get _totalSteps {
    return switch (_type) {
      ProfileType.urban => 7,
      ProfileType.kids => 9,
      ProfileType.pro => 6,
    };
  }

  bool get _isTransitionStep {
    if (_type == ProfileType.urban) {
      return _stepIndex == 0 || _stepIndex == 6;
    } else if (_type == ProfileType.kids) {
      return _stepIndex == 0 || _stepIndex == 8;
    } else {
      return _stepIndex == 0 || _stepIndex == 5;
    }
  }

  bool get _isLastStep => _stepIndex == _totalSteps - 1;

  // Etape RGPD (avant-derniere = ou on soumet Firebase)
  int get _rgpdStep {
    return switch (_type) {
      ProfileType.urban => 5,
      ProfileType.kids => 7,
      ProfileType.pro => 4,
    };
  }

  // -- Lifecycle

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _slideCtrl = AnimationController(
      vsync: this,
      duration: SmartSoleDesign.animNormal,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _cabinetCodeCtrl.dispose();
    _childNicknameCtrl.dispose();
    super.dispose();
  }

  // -- Navigation

  GlobalKey<FormState> _formKeyFor(int index) {
    _formKeys[index] ??= GlobalKey<FormState>();
    return _formKeys[index]!;
  }

  bool _validateCurrentStep() {
    final key = _formKeys[_stepIndex];
    if (key != null && key.currentState != null) {
      return key.currentState!.validate();
    }
    return true;
  }

  Future<void> _nextStep() async {
    final auth = ref.read(authProvider.notifier);

    // Validation avant de passer
    if (!_isTransitionStep) {
      if (!_validateCurrentStep()) return;

      // Verification specifique selon type + etape
      if (_type == ProfileType.urban) {
        if (_stepIndex == 3 && _gender == null) {
          _showSnack('Veuillez selectionner votre genre.');
          return;
        }
      } else if (_type == ProfileType.kids) {
        if (_stepIndex == 5 && _gender == null) {
          _showSnack('Veuillez selectionner le genre de votre enfant.');
          return;
        }
        if (_stepIndex == 2) {
          // Gestion speciale PIN
          if (!_pinConfirmMode) {
            if (_pinCursor < 4) {
              _showSnack('Veuillez saisir les 4 chiffres de votre PIN.');
              return;
            }
            setState(() {
              _pinConfirmMode = true;
              _pinError = null;
            });
            await _animateSlide(forward: true);
            return;
          } else {
            if (_pinConfirmCursor < 4) {
              _showSnack('Veuillez confirmer votre PIN.');
              return;
            }
            final p1 = _pin.join();
            final p2 = _pinConfirm.join();
            if (p1 != p2) {
              setState(() {
                _pinConfirm.fillRange(0, 4, '');
                _pinConfirmCursor = 0;
                _pinError = 'Les PINs ne correspondent pas. Reessayez.';
              });
              HapticFeedback.mediumImpact();
              return;
            }
            setState(() => _pinError = null);
          }
        }
      } else if (_type == ProfileType.pro) {
        if (_stepIndex == 1 && !_isCabinetCodeValid) {
          _showSnack('Veuillez valider votre code cabinet avant de continuer.');
          return;
        }
        if (_stepIndex == 3 && _gender == null) {
          // Pro n'a pas d'etape genre, ignorer
        }
      }
    }

    // Soumission Firebase sur l'etape RGPD
    if (_stepIndex == _rgpdStep) {
      final success = await _submitFirebase(auth);
      if (!success) return;
    }

    await _animateSlide(forward: true);
    setState(() {
      _stepIndex++;
    });

    // Declencher animation de succes sur le dernier ecran
    if (_isLastStep) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _showSuccessCheck = true);
      });
    }
  }

  void _prevStep() {
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }

    // Gestion retour dans le PIN kids (mode confirmation)
    if (_type == ProfileType.kids && _stepIndex == 2 && _pinConfirmMode) {
      setState(() {
        _pinConfirmMode = false;
        _pinConfirm.fillRange(0, 4, '');
        _pinConfirmCursor = 0;
        _pinError = null;
      });
      return;
    }

    _animateSlide(forward: false).then((_) {
      setState(() {
        _stepIndex--;
      });
    });
  }

  Future<void> _animateSlide({required bool forward}) async {
    _slideCtrl.reset();
    _slideAnim = Tween<Offset>(
      begin: Offset(forward ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    await _slideCtrl.forward();
  }

  // -- Firebase

  Future<bool> _submitFirebase(dynamic auth) async {
    auth.clearError();

    final profile = _profile.copyWith(
      email: _emailCtrl.text.trim(),
      displayName: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : null,
      gender: _gender,
      shoeSize: _type == ProfileType.kids ? _childShoeSize : _shoeSize,
      heightCm: _heightCtrl.text.isNotEmpty
          ? double.tryParse(_heightCtrl.text)
          : null,
      weightKg: _weightCtrl.text.isNotEmpty
          ? double.tryParse(_weightCtrl.text)
          : null,
      isOnboardingComplete: true,
      consentCloud: _consentCloud,
      consentAnalytics: _consentAnalytics,
      consentPush: _consentPush,
      childProfile: _type == ProfileType.kids && _childNicknameCtrl.text.isNotEmpty
          ? ChildProfile(
              nickname: _childNicknameCtrl.text.trim(),
              birthMonth: _childBirthMonth ?? 1,
              birthYear: _childBirthYear ?? 2015,
            )
          : null,
    );

    setState(() => _profile = profile);

    bool success = false;
    if (_type == ProfileType.kids) {
      success = await auth.signUpKids(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        pin: _pin.join(),
        profile: profile,
      );
    } else {
      success = await auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        profile: profile,
      );
    }

    return success;
  }

  // -- Helpers

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _navigateHome() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: SmartSoleColors.darkBg,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          Future.delayed(const Duration(milliseconds: 2800), () {
            if (ctx.mounted) {
              Navigator.of(ctx).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: {
                  'profileType': _profile.profileType,
                  'showBlePrompt': true,
                },
              );
            }
          });
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: Scaffold(
              backgroundColor: SmartSoleColors.darkBg,
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      SvgPicture.asset(
                        'assets/images/login_or_singn_in_succes.svg',
                        width: 300,
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 36),
                      const Text(
                        'Inscription réussie !',
                        style: TextStyle(
                          fontFamily: 'Articulat CF',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Bienvenue sur Smartsole',
                        style: TextStyle(
                          fontFamily: 'Articulat CF',
                          fontSize: 15,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SvgPicture.asset(
                        'assets/images/loading.svg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -- Build

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _prevStep();
      },
      child: Scaffold(
        backgroundColor: isDark ? SmartSoleColors.darkBg : SmartSoleColors.lightBg,
        body: SafeArea(
          child: Column(
            children: [
              if (!_isTransitionStep) _buildTopBar(isDark),
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildCurrentStep(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Top Bar

  Widget _buildTopBar(bool isDark) {
    // Etapes non-transition : progression 1-based, en excluant les etapes transition
    final nonTransitionTotal = _totalSteps - 2; // exclure step 0 et derniere
    final nonTransitionCurrent = _stepIndex; // 1 = premiere non-transition

    final progress = nonTransitionTotal > 0
        ? (nonTransitionCurrent / nonTransitionTotal).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: isDark
                    ? SmartSoleColors.textSecondaryDark
                    : SmartSoleColors.textSecondaryLight,
                onPressed: _prevStep,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Etape $nonTransitionCurrent/$nonTransitionTotal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? SmartSoleColors.textTertiaryDark
                            : SmartSoleColors.textTertiaryLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          SmartSoleColors.biNormal,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -- Step Router

  Widget _buildCurrentStep(bool isDark) {
    return switch (_type) {
      ProfileType.urban => _buildUrbanStep(isDark),
      ProfileType.kids => _buildKidsStep(isDark),
      ProfileType.pro => _buildProStep(isDark),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // URBAN STEPS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildUrbanStep(bool isDark) {
    return switch (_stepIndex) {
      0 => _buildTransitionWelcome(
          isDark: isDark,
          svgAsset: 'assets/images/transition_screen_image2.svg',
          title: 'Sautez le pas',
          subtitle: 'Creez votre espace personnel en quelques etapes.',
          buttonLabel: 'Commencer',
          onButton: _nextStep,
        ),
      1 => _buildStepIdentifiants(isDark),
      2 => _buildStepDisplayName(isDark),
      3 => _buildStepGenre(isDark, forChild: false),
      4 => _buildStepBiometrie(isDark),
      5 => _buildStepConsentements(isDark),
      6 => _buildTransitionSuccess(
          isDark: isDark,
          svgAsset: 'assets/images/transition_screen_image2.svg',
          title: 'Compte cree !',
          subtitle: 'Vos donnees sont pretes. Bonne marche !',
          buttonLabel: "Commencer l'experience",
          onButton: _navigateHome,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // KIDS STEPS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildKidsStep(bool isDark) {
    return switch (_stepIndex) {
      0 => _buildTransitionWelcome(
          isDark: isDark,
          svgAsset: 'assets/images/undraw_dog-walking_w27q.svg',
          title: 'Espace Parent',
          subtitle:
              'Suivez le developpement de la marche de votre enfant.',
          buttonLabel: 'Commencer',
          onButton: _nextStep,
        ),
      1 => _buildStepIdentifiants(isDark, labelPrefix: 'parent'),
      2 => _buildStepPin(isDark),
      3 => _buildStepDisplayName(isDark,
          title: 'Votre prenom',
          hint: 'Prenom ou surnom'),
      4 => _buildStepChildInfo(isDark),
      5 => _buildStepGenre(isDark, forChild: true),
      6 => _buildStepChildShoeSize(isDark),
      7 => _buildStepConsentements(isDark),
      8 => _buildTransitionSuccess(
          isDark: isDark,
          svgAsset: 'assets/images/transition_screen_image2.svg',
          title: 'Compte cree !',
          subtitle: 'Le suivi de votre enfant est pret.',
          buttonLabel: 'Acceder au suivi',
          onButton: _navigateHome,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRO STEPS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProStep(bool isDark) {
    return switch (_stepIndex) {
      0 => _buildTransitionWelcomePro(isDark),
      1 => _buildStepCabinetCode(isDark),
      2 => _buildStepIdentifiants(isDark, labelPrefix: 'professionnel'),
      3 => _buildStepDisplayName(isDark,
          title: 'Votre identite professionnelle',
          hint: 'Nom d\'affichage (ex: Dr. Martin)'),
      4 => _buildStepConsentements(isDark),
      5 => _buildTransitionSuccess(
          isDark: isDark,
          svgAsset: 'assets/images/transition_screen_image2.svg',
          title: 'Acces Pro active !',
          subtitle: 'Votre espace clinicien est pret.',
          buttonLabel: 'Acceder au tableau de bord',
          onButton: _navigateHome,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED STEPS
  // ─────────────────────────────────────────────────────────────────────────

  // -- Transition Welcome (generique)

  Widget _buildTransitionWelcome({
    required bool isDark,
    required String svgAsset,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? SmartSoleColors.meshDarkGradient
            : null,
        color: isDark ? null : SmartSoleColors.lightBg,
      ),
      child: Stack(
        children: [
          // Orbs decoratifs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biNormal.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biTeal.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  svgAsset,
                  height: 220,
                  placeholderBuilder: (_) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SmartSoleColors.biNormal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(
                    color: isDark
                        ? SmartSoleColors.textSecondaryDark
                        : SmartSoleColors.textSecondaryLight,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _GradientButton(
                  label: buttonLabel,
                  onTap: onButton,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Transition Welcome PRO

  Widget _buildTransitionWelcomePro(bool isDark) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? SmartSoleColors.meshDarkGradient : null,
        color: isDark ? null : SmartSoleColors.lightBg,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biNavy.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biTeal.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/transition_screen_image2.svg',
                  height: 200,
                  placeholderBuilder: (_) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SmartSoleColors.biNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Badge "Espace Clinicien"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SmartSoleColors.biNavy.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SmartSoleColors.biNavy.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_hospital_outlined,
                        color: SmartSoleColors.biNavy,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Espace Clinicien',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: SmartSoleColors.biNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bienvenue, professionnel de santé',
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Acces securise avec votre code cabinet.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(
                    color: isDark
                        ? SmartSoleColors.textSecondaryDark
                        : SmartSoleColors.textSecondaryLight,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                _GradientButton(
                  label: 'Commencer',
                  onTap: _nextStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Transition Success

  Widget _buildTransitionSuccess({
    required bool isDark,
    required String svgAsset,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onButton,
  }) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            svgAsset,
            height: 200,
            placeholderBuilder: (_) => const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: SmartSoleColors.biSuccess,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            width: _showSuccessCheck ? 72 : 0,
            height: _showSuccessCheck ? 72 : 0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SmartSoleColors.biSuccess.withValues(alpha: 0.15),
              border: Border.all(
                color: SmartSoleColors.biSuccess.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: _showSuccessCheck
                ? const Icon(
                    Icons.check_rounded,
                    color: SmartSoleColors.biSuccess,
                    size: 36,
                  )
                : null,
          ),
          if (_showSuccessCheck) const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: isDark
                  ? SmartSoleColors.textSecondaryDark
                  : SmartSoleColors.textSecondaryLight,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          _GradientButton(
            label: buttonLabel,
            onTap: onButton,
          ),
        ],
      ),
    );
  }

  // -- Etape : Identifiants (email + mot de passe)

  Widget _buildStepIdentifiants(bool isDark, {String labelPrefix = ''}) {
    final formKey = _formKeyFor(_stepIndex);
    final emailLabel = labelPrefix.isNotEmpty
        ? 'Email $labelPrefix'
        : 'Email';
    final emailHint = labelPrefix == 'pro'
        ? 'dr.amara@cabinet.fr'
        : labelPrefix == 'parent'
            ? 'parent@email.fr'
            : 'thomas@smartsole.io';

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: labelPrefix == 'professionnel'
                ? 'Votre compte professionnel'
                : labelPrefix == 'parent'
                    ? 'Votre compte parent'
                    : 'Creez votre compte',
            subtitle: 'Ces informations restent confidentielles.',
          ),
          const SizedBox(height: 32),
          Form(
            key: formKey,
            child: Column(
              children: [
                _JourneyField(
                  controller: _emailCtrl,
                  label: emailLabel,
                  hint: emailHint,
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _JourneyField(
                  controller: _passCtrl,
                  label: 'Mot de passe',
                  hint: '--------',
                  icon: Icons.lock_outline,
                  isDark: isDark,
                  obscure: _obscurePass,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return '6 caracteres minimum';
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                      color: isDark
                          ? SmartSoleColors.textTertiaryDark
                          : SmartSoleColors.textTertiaryLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildErrorBanner(),
          const SizedBox(height: 16),
          _GradientButton(label: 'Suivant', onTap: _nextStep),
        ],
      ),
    );
  }

  // -- Etape : Nom d'affichage

  Widget _buildStepDisplayName(
    bool isDark, {
    String title = 'Comment vous appelle-t-on ?',
    String hint = 'Prenom ou nom d\'affichage',
  }) {
    final formKey = _formKeyFor(_stepIndex);

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: title,
            subtitle: null,
            iconWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biNormal.withValues(alpha: 0.15),
                border: Border.all(
                  color: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/step_white.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    SmartSoleColors.biNormal,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: formKey,
            child: _JourneyField(
              controller: _nameCtrl,
              label: 'Prenom ou nom d\'affichage',
              hint: hint,
              icon: Icons.person_outline,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ce champ est requis';
                return null;
              },
            ),
          ),
          const SizedBox(height: 32),
          _GradientButton(label: 'Suivant', onTap: _nextStep),
        ],
      ),
    );
  }

  // -- Etape : Genre

  Widget _buildStepGenre(bool isDark, {required bool forChild}) {

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: forChild
                ? 'Le genre de votre enfant'
                : 'Quel est votre genre ?',
            subtitle: 'Utilise pour calibrer les normes biomecanique IMM.',
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  isDark: isDark,
                  label: 'Homme',
                  svgAsset: 'assets/images/man_avatar.svg',
                  isSelected: _gender == UserGender.male,
                  onTap: () => setState(() => _gender = UserGender.male),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderCard(
                  isDark: isDark,
                  label: 'Femme',
                  svgAsset: 'assets/images/girl_avatar.svg',
                  isSelected: _gender == UserGender.female,
                  onTap: () => setState(() => _gender = UserGender.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _GradientButton(label: 'Suivant', onTap: _nextStep),
        ],
      ),
    );
  }

  // -- Etape : Biometrie

  Widget _buildStepBiometrie(bool isDark) {
    final shoeSizes = _adultShoeSizes();

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: 'Quelques mesures',
            subtitle: 'Pour calibrer votre analyse biomecanique.',
            iconWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biNormal.withValues(alpha: 0.12),
                border: Border.all(
                  color: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/left_foot.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    SmartSoleColors.biNormal,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _JourneyField(
            controller: _heightCtrl,
            label: 'Taille (cm)',
            hint: '175',
            icon: Icons.height,
            isDark: isDark,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          _JourneyField(
            controller: _weightCtrl,
            label: 'Poids (kg)',
            hint: '70',
            icon: Icons.monitor_weight_outlined,
            isDark: isDark,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          _DropdownField<double>(
            isDark: isDark,
            label: 'Pointure',
            hint: 'Selectionnez',
            icon: Icons.straighten,
            value: _shoeSize,
            items: shoeSizes,
            displayBuilder: (v) => v % 1 == 0
                ? v.toInt().toString()
                : v.toString(),
            onChanged: (v) => setState(() => _shoeSize = v),
          ),
          const SizedBox(height: 32),
          _GradientButton(label: 'Suivant', onTap: _nextStep),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _nextStep,
              child: Text(
                'Passer cette etape',
                style: TextStyle(
                  color: isDark
                      ? SmartSoleColors.textTertiaryDark
                      : SmartSoleColors.textTertiaryLight,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Etape : Consentements RGPD

  Widget _buildStepConsentements(bool isDark) {
    final authState = ref.watch(authProvider);

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: 'Vos donnees vous appartiennent',
            subtitle: 'Conformite RGPD -- vous gardez le controle.',
            iconWidget: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biTeal.withValues(alpha: 0.12),
                border: Border.all(
                  color: SmartSoleColors.biTeal.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: SmartSoleColors.biTeal,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ConsentTile(
            isDark: isDark,
            title: 'Synchronisation cloud',
            subtitle:
                'Sauvegardez vos sessions et accedez-y sur tous vos appareils.',
            value: _consentCloud,
            onChanged: (v) => setState(() => _consentCloud = v),
          ),
          _ConsentTile(
            isDark: isDark,
            title: 'Analyses anonymisees',
            subtitle:
                'Contribuez a l\'amelioration de SmartSole (donnees anonymes).',
            value: _consentAnalytics,
            onChanged: (v) => setState(() => _consentAnalytics = v),
          ),
          _ConsentTile(
            isDark: isDark,
            title: 'Notifications push',
            subtitle:
                'Recevez vos rapports hebdomadaires et alertes posturales.',
            value: _consentPush,
            onChanged: (v) => setState(() => _consentPush = v),
          ),
          const SizedBox(height: 32),
          _buildErrorBanner(),
          const SizedBox(height: 12),
          _GradientButton(
            label: authState.isLoading ? '' : 'Continuer',
            isLoading: authState.isLoading,
            onTap: authState.isLoading ? null : _nextStep,
          ),
        ],
      ),
    );
  }

  // -- Etape : PIN Kids

  Widget _buildStepPin(bool isDark) {
    final isConfirm = _pinConfirmMode;
    final cursor = isConfirm ? _pinConfirmCursor : _pinCursor;

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StepHeader(
            isDark: isDark,
            title: isConfirm ? 'Confirmez votre PIN' : 'Choisissez votre PIN',
            subtitle: isConfirm
                ? 'Saisissez a nouveau votre code PIN pour confirmer.'
                : 'Ce PIN remplacera votre mot de passe au quotidien.',
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          const SizedBox(height: 32),
          // PIN indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < cursor;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? SmartSoleColors.biTeal
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.15)),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: SmartSoleColors.biTeal.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              );
            }),
          ),
          if (_pinError != null) ...[
            const SizedBox(height: 12),
            Text(
              _pinError!,
              style: TextStyle(
                color: SmartSoleColors.biAlert,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 28),
          // PIN Pad
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (int d = 1; d <= 9; d++)
                _PinKey(
                  digit: '$d',
                  isDark: isDark,
                  onTap: () => _onPinDigit('$d', isConfirm: isConfirm),
                ),
              _PinKey(
                digit: '<-',
                isDark: isDark,
                isDelete: true,
                onTap: () => _onPinDelete(isConfirm: isConfirm),
              ),
              _PinKey(
                digit: '0',
                isDark: isDark,
                onTap: () => _onPinDigit('0', isConfirm: isConfirm),
              ),
              _PinKey(
                digit: 'OK',
                isDark: isDark,
                isConfirm: true,
                onTap: _nextStep,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPinDigit(String d, {required bool isConfirm}) {
    setState(() {
      if (isConfirm) {
        if (_pinConfirmCursor >= 4) return;
        _pinConfirm[_pinConfirmCursor] = d;
        _pinConfirmCursor++;
      } else {
        if (_pinCursor >= 4) return;
        _pin[_pinCursor] = d;
        _pinCursor++;
      }
      _pinError = null;
    });
  }

  void _onPinDelete({required bool isConfirm}) {
    setState(() {
      if (isConfirm) {
        if (_pinConfirmCursor <= 0) return;
        _pinConfirmCursor--;
        _pinConfirm[_pinConfirmCursor] = '';
      } else {
        if (_pinCursor <= 0) return;
        _pinCursor--;
        _pin[_pinCursor] = '';
      }
    });
  }

  // -- Etape : Infos enfant

  Widget _buildStepChildInfo(bool isDark) {
    final formKey = _formKeyFor(_stepIndex);
    final months = [
      'Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre',
    ];
    final years = List.generate(2025 - 2010 + 1, (i) => 2010 + i).reversed.toList();

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: 'Parlez-nous de votre enfant',
            subtitle: null,
            iconWidget: SvgPicture.asset(
              'assets/images/step_orange.svg',
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                SmartSoleColors.biNormal,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: formKey,
            child: Column(
              children: [
                _JourneyField(
                  controller: _childNicknameCtrl,
                  label: "Prenom de l'enfant",
                  hint: 'Lucas',
                  icon: Icons.child_care,
                  isDark: isDark,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Prenom requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _DropdownField<int>(
                  isDark: isDark,
                  label: 'Mois de naissance',
                  hint: 'Selectionnez',
                  icon: Icons.calendar_month_outlined,
                  value: _childBirthMonth,
                  items: List.generate(12, (i) => i + 1),
                  displayBuilder: (v) => months[v - 1],
                  onChanged: (v) => setState(() => _childBirthMonth = v),
                ),
                const SizedBox(height: 14),
                _DropdownField<int>(
                  isDark: isDark,
                  label: 'Annee de naissance',
                  hint: 'Selectionnez',
                  icon: Icons.calendar_today_outlined,
                  value: _childBirthYear,
                  items: years,
                  displayBuilder: (v) => v.toString(),
                  onChanged: (v) => setState(() => _childBirthYear = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _GradientButton(label: 'Suivant', onTap: _nextStep),
        ],
      ),
    );
  }

  // -- Etape : Pointure enfant

  Widget _buildStepChildShoeSize(bool isDark) {
    final sizes = List.generate(38 - 18 + 1, (i) => (18 + i).toDouble());

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: "La pointure de votre enfant",
            subtitle: null,
            iconWidget: SvgPicture.asset(
              'assets/images/right_foot.svg',
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                SmartSoleColors.biNormal,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _DropdownField<double>(
            isDark: isDark,
            label: 'Pointure',
            hint: 'Selectionnez',
            icon: Icons.straighten,
            value: _childShoeSize,
            items: sizes,
            displayBuilder: (v) => v.toInt().toString(),
            onChanged: (v) => setState(() => _childShoeSize = v),
          ),
          const SizedBox(height: 32),
          _GradientButton(label: 'Suivant', onTap: _nextStep),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _nextStep,
              child: Text(
                'Passer cette etape',
                style: TextStyle(
                  color: isDark
                      ? SmartSoleColors.textTertiaryDark
                      : SmartSoleColors.textTertiaryLight,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Etape : Code cabinet PRO

  Widget _buildStepCabinetCode(bool isDark) {
    final formKey = _formKeyFor(_stepIndex);
    final authState = ref.watch(authProvider);

    return _StepScaffold(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            isDark: isDark,
            title: 'Votre code cabinet',
            subtitle: 'Requis pour acceder a l\'espace professionnel.',
            iconWidget: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biNavy.withValues(alpha: 0.12),
                border: Border.all(
                  color: SmartSoleColors.biNavy.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                color: SmartSoleColors.biNavy,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Form(
            key: formKey,
            child: _JourneyField(
              controller: _cabinetCodeCtrl,
              label: 'Code cabinet',
              hint: 'ex: CAB-2026',
              icon: Icons.vpn_key_outlined,
              isDark: isDark,
              suffixIcon: _isCabinetCodeValid
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: SmartSoleColors.biSuccess,
                    )
                  : null,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Code requis';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_isCabinetCodeValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SmartSoleColors.biSuccess.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SmartSoleColors.biSuccess.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: SmartSoleColors.biSuccess,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Code cabinet valide.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SmartSoleColors.biSuccess,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          _buildErrorBanner(),
          const SizedBox(height: 24),
          if (!_isCabinetCodeValid)
            _GradientButton(
              label: _isVerifyingCode ? '' : 'Verifier',
              isLoading: _isVerifyingCode,
              onTap: _isVerifyingCode ? null : () => _verifyCabinetCode(),
              gradient: const LinearGradient(
                colors: [SmartSoleColors.biNavy, Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          if (_isCabinetCodeValid)
            _GradientButton(label: 'Suivant', onTap: _nextStep),
        ],
      ),
    );
  }

  Future<void> _verifyCabinetCode() async {
    final key = _formKeys[_stepIndex];
    if (key != null && !(key.currentState?.validate() ?? true)) return;

    final auth = ref.read(authProvider.notifier);
    auth.clearError();
    setState(() => _isVerifyingCode = true);

    final code = _cabinetCodeCtrl.text.trim();
    final valid = await auth.validateCabinetCode(code);

    if (mounted) {
      setState(() {
        _isCabinetCodeValid = valid;
        _isVerifyingCode = false;
      });

      if (!valid) {
        _showSnack('Code cabinet invalide ou inexistant.');
      }
    }
  }

  // -- Error Banner

  Widget _buildErrorBanner() {
    final authState = ref.watch(authProvider);
    final msg = authState.errorMessage;
    if (msg == null || msg.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SmartSoleColors.biAlert.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SmartSoleColors.biAlert.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 16,
              color: SmartSoleColors.biAlert,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  color: SmartSoleColors.biAlert,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Helpers

  List<double> _adultShoeSizes() {
    return [
      36.0, 36.5, 37.0, 37.5, 38.0, 38.5, 39.0, 39.5, 40.0, 40.5,
      41.0, 41.5, 42.0, 42.5, 43.0, 43.5, 44.0, 44.5, 45.0, 45.5,
      46.0, 47.0, 48.0,
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// -- Step Scaffold

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: child,
    );
  }
}

// -- Step Header

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.isDark,
    required this.title,
    required this.subtitle,
    this.iconWidget,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final bool isDark;
  final String title;
  final String? subtitle;
  final Widget? iconWidget;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (iconWidget != null) ...[
          iconWidget!,
          const SizedBox(height: 16),
        ],
        Text(
          title,
          textAlign: crossAxisAlignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.start,
          style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: tt.bodyMedium?.copyWith(
              color: isDark
                  ? SmartSoleColors.textSecondaryDark
                  : SmartSoleColors.textSecondaryLight,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}

// -- Gradient Button

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.gradient,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? SmartSoleColors.heroGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: SmartSoleColors.biNormal.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: tt.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// -- Journey Field

class _JourneyField extends StatelessWidget {
  const _JourneyField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.80);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF111827),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: SmartSoleColors.biTeal,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: SmartSoleColors.biAlert.withValues(alpha: 0.7),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SmartSoleColors.biAlert),
        ),
      ),
    );
  }
}

// -- Dropdown Field

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.isDark,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.displayBuilder,
    required this.onChanged,
  });

  final bool isDark;
  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) displayBuilder;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.80);
    final textColor =
        isDark ? Colors.white : const Color(0xFF111827);

    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(
          color: isDark
              ? SmartSoleColors.textTertiaryDark
              : SmartSoleColors.textTertiaryLight,
          fontSize: 14,
        ),
      ),
      dropdownColor: isDark ? SmartSoleColors.darkCard : Colors.white,
      style: TextStyle(color: textColor, fontSize: 14),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark
            ? SmartSoleColors.textTertiaryDark
            : SmartSoleColors.textTertiaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: SmartSoleColors.biTeal,
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(displayBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// -- Gender Card

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.isDark,
    required this.label,
    required this.svgAsset,
    required this.isSelected,
    required this.onTap,
  });

  final bool isDark;
  final String label;
  final String svgAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SmartSoleDesign.animNormal,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? SmartSoleColors.biNormal.withValues(alpha: 0.10)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? SmartSoleColors.biNormal
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              svgAsset,
              width: 60,
              height: 60,
              placeholderBuilder: (_) => const SizedBox(
                width: 60,
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SmartSoleColors.biNormal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SmartSoleColors.biNormal,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 13,
                ),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.15),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              label,
              style: tt.titleSmall?.copyWith(
                color: isSelected
                    ? SmartSoleColors.biNormal
                    : (isDark
                        ? SmartSoleColors.textPrimaryDark
                        : SmartSoleColors.textPrimaryLight),
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Consent Tile

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: tt.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: tt.bodySmall?.copyWith(
              color: isDark
                  ? SmartSoleColors.textSecondaryDark
                  : SmartSoleColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: SmartSoleColors.biTeal,
          inactiveThumbColor: isDark
              ? SmartSoleColors.textTertiaryDark
              : SmartSoleColors.textTertiaryLight,
          inactiveTrackColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

// -- PIN Key

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.digit,
    required this.onTap,
    required this.isDark,
    this.isDelete = false,
    this.isConfirm = false,
  });

  final String digit;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDelete;
  final bool isConfirm;

  @override
  Widget build(BuildContext context) {
    final Color bg = isConfirm
        ? SmartSoleColors.biTeal.withValues(alpha: 0.85)
        : isDelete
            ? SmartSoleColors.biAlert.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05));

    final Color textColor = isConfirm
        ? Colors.white
        : isDelete
            ? SmartSoleColors.biAlert
            : (isDark ? Colors.white : const Color(0xFF111827));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
