import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen v3 — Connexion uniquement (sign-in only)
//
// Comportement selon le profil :
//   • Urban   → Email + password (connexion)
//   • Kids    → PIN 4 chiffres (connexion)
//   • Pro     → Email + password + code cabinet (connexion)
//
// L'inscription est gérée par /register → RegistrationJourneyScreen.
// Gestion d'erreurs Firebase traduite en français via AuthService.translateError.
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _proCodeCtrl = TextEditingController();

  // Mot de passe affiché / masqué
  bool _obscurePass = true;

  // PIN kids (4 chiffres)
  final List<String> _pinDigits = ['', '', '', ''];
  int _pinCursor = 0;

  // Email envoyé pour reset
  bool _resetSent = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _proCodeCtrl.dispose();
    super.dispose();
  }

  ProfileType get _type => widget.profile.profileType;

  // ── Authentification principale ──────────────────────────────────────────

  Future<void> _authenticate() async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (_type == ProfileType.pro) {
      final code = _proCodeCtrl.text.trim();
      if (code.isEmpty) {
        _showSnack('Veuillez saisir votre code cabinet.');
        return;
      }
      final validCode = await auth.validateCabinetCode(code);
      if (!mounted) return;
      if (!validCode) {
        _showSnack('Code cabinet invalide ou inexistant.');
        return;
      }
    }

    final success = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);

    if (success && mounted) {
      _showSuccessAndNavigate();
    }
  }

  // ── Réinitialisation mot de passe ─────────────────────────────────────────

  Future<void> _onForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Entrez votre email pour réinitialiser le mot de passe.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(email);
    if (ok && mounted) {
      setState(() => _resetSent = true);
      _showSnack('Email de réinitialisation envoyé à $email');
    }
  }

  // ── Flux Kids ────────────────────────────────────────────────────────────

  void _onPinDigit(String d) {
    if (_pinCursor >= 4) return;
    setState(() {
      _pinDigits[_pinCursor] = d;
      _pinCursor++;
    });
  }

  void _onPinDelete() {
    if (_pinCursor <= 0) return;
    setState(() {
      _pinCursor--;
      _pinDigits[_pinCursor] = '';
    });
  }

  Future<void> _onPinConfirm() async {
    if (_pinCursor < 4) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    // Connexion kids : PIN (re-auth silencieuse si session expirée)
    final ok = await auth.signInWithKidsPin(pin: _pinDigits.join());
    if (ok && mounted) {
      _showSuccessAndNavigate();
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _pinDigits.fillRange(0, 4, '');
        _pinCursor = 0;
      });
    }
  }

  // ── Transition succès post-login ────────────────────────────────────────

  void _showSuccessAndNavigate() {
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
                arguments: {'profileType': _type, 'showBlePrompt': true},
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
                      // Logo en haut
                      Image.asset(
                        'assets/images/logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      // Illustration principale
                      Image.asset(
                        'assets/images/walk1.gif',
                        width: 300,
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Connexion réussie !',
                        style: const TextStyle(
                          fontFamily: 'Articulat CF',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bienvenue sur Smartsole',
                        style: const TextStyle(
                          fontFamily: 'Articulat CF',
                          fontSize: 15,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Loader SVG
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _BackgroundMesh(isDark: isDark)),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(tt, isDark),
                        const SizedBox(height: 36),
                        _buildFormCard(tt, isDark),
                        const SizedBox(height: 16),
                        _buildErrorBanner(),
                        const SizedBox(height: 16),
                        _buildActionButton(tt, isDark),
                        const SizedBox(height: 20),
                        _buildRegisterLink(tt, isDark),
                        const SizedBox(height: 32),
                        _buildFooter(tt, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(TextTheme tt, bool isDark) {
    final (icon, title, sub) = switch (_type) {
      ProfileType.urban => (
        Icons.directions_walk,
        'Bon retour',
        'Connectez-vous pour accéder à votre analyse.',
      ),
      ProfileType.kids => (
        Icons.child_care,
        'Espace Parent',
        'Entrez votre code PIN pour accéder au suivi.',
      ),
      ProfileType.pro => (
        Icons.local_hospital_outlined,
        'Espace Clinicien',
        'Connexion sécurisée pour professionnels de santé.',
      ),
    };

    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          'SmartSole',
          style: tt.labelSmall?.copyWith(
            color: SmartSoleColors.biTeal,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            color:
                isDark
                    ? SmartSoleColors.textSecondaryDark
                    : SmartSoleColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  // ── Carte formulaire ─────────────────────────────────────────────────────

  Widget _buildFormCard(TextTheme tt, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.07),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_type) {
            ProfileType.urban => _buildEmailForm(isDark),
            ProfileType.kids => _buildKidsForm(isDark),
            ProfileType.pro => _buildProForm(isDark),
          },
        ),
      ),
    );
  }

  // ── Formulaire Urban (email + password) ──────────────────────────────────

  Widget _buildEmailForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _AuthField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'thomas@smartsole.io',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _passCtrl,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color:
                    isDark
                        ? SmartSoleColors.textTertiaryDark
                        : SmartSoleColors.textTertiaryLight,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _onForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _resetSent ? 'Email envoyé ✓' : 'Mot de passe oublié ?',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      _resetSent
                          ? SmartSoleColors.biSuccess
                          : SmartSoleColors.biTeal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulaire Pro ────────────────────────────────────────────────────────

  Widget _buildProForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _AuthField(
            controller: _emailCtrl,
            label: 'Email professionnel',
            hint: 'dr.amara@cabinet.fr',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _passCtrl,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color:
                    isDark
                        ? SmartSoleColors.textTertiaryDark
                        : SmartSoleColors.textTertiaryLight,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _proCodeCtrl,
            label: 'Code cabinet',
            hint: 'ex: CAB-2026',
            icon: Icons.local_hospital_outlined,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code cabinet requis';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _onForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Mot de passe oublié ?',
                style: TextStyle(fontSize: 12, color: SmartSoleColors.biTeal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulaire Kids — PIN connexion uniquement ────────────────────────────

  Widget _buildKidsForm(bool isDark) {
    return _buildPinPad(isDark);
  }

  Widget _buildPinPad(bool isDark) {
    return Column(
      children: [
        // Indicateurs PIN
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _pinCursor;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    filled
                        ? SmartSoleColors.biTeal
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.15)),
                boxShadow:
                    filled
                        ? [
                          BoxShadow(
                            color: SmartSoleColors.biTeal.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 8,
                          ),
                        ]
                        : [],
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            for (int d = 1; d <= 9; d++)
              _PinKey(
                digit: '$d',
                onTap: () => _onPinDigit('$d'),
                isDark: isDark,
              ),
            _PinKey(
              digit: '⌫',
              onTap: _onPinDelete,
              isDark: isDark,
              isDelete: true,
            ),
            _PinKey(digit: '0', onTap: () => _onPinDigit('0'), isDark: isDark),
            _PinKey(
              digit: '✓',
              onTap: _onPinConfirm,
              isDark: isDark,
              isConfirm: true,
            ),
          ],
        ),
      ],
    );
  }

  // ── Bannière d'erreur ─────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        final msg = auth.errorMessage;
        if (msg == null) return const SizedBox.shrink();
        return AnimatedOpacity(
          opacity: msg.isNotEmpty ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SmartSoleColors.biAlert.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SmartSoleColors.biAlert.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: SmartSoleColors.biAlert,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg,
                    style: TextStyle(
                      fontSize: 13,
                      color: SmartSoleColors.biAlert,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bouton d'action ───────────────────────────────────────────────────────

  Widget _buildActionButton(TextTheme tt, bool isDark) {
    // Kids : le ✓ du PIN pad est l'action principale, bouton masqué
    if (_type == ProfileType.kids) {
      return const SizedBox.shrink();
    }

    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: SmartSoleColors.heroGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: SmartSoleColors.biTeal.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: auth.isLoading ? null : _authenticate,
              child: Center(
                child:
                    auth.isLoading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Se connecter',
                              style: tt.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Lien inscription ──────────────────────────────────────────────────────

  Widget _buildRegisterLink(TextTheme tt, bool isDark) {
    return TextButton(
      onPressed:
          () => Navigator.of(context).pushReplacementNamed('/onboarding'),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: SmartSoleColors.textSecondaryDark,
          ),
          children: [
            const TextSpan(text: "Pas encore de compte ? "),
            TextSpan(
              text: "S'inscrire",
              style: const TextStyle(
                color: SmartSoleColors.biTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(TextTheme tt, bool isDark) {
    final subtleColor =
        isDark
            ? SmartSoleColors.textTertiaryDark
            : SmartSoleColors.textTertiaryLight;
    return Column(
      children: [
        Text(
          'Données protégées — conformité RGPD',
          style: TextStyle(fontSize: 11, color: subtleColor),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 12, color: subtleColor),
            const SizedBox(width: 4),
            Text(
              'SmartSole © 2026 · MVP v1.0',
              style: TextStyle(fontSize: 11, color: subtleColor),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Background animated mesh ────────────────────────────────────────────────

class _BackgroundMesh extends StatelessWidget {
  const _BackgroundMesh({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [const Color(0xFF0A0E1A), const Color(0xFF0D1B2A)]
                  : [const Color(0xFFF0FDF8), const Color(0xFFE0F2FE)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartSoleColors.biTeal.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Field avec validation ─────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
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

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.10);
    final fillColor =
        isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.80);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
          borderSide: BorderSide(color: SmartSoleColors.biTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: SmartSoleColors.biAlert.withValues(alpha: 0.7),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: SmartSoleColors.biAlert),
        ),
      ),
    );
  }
}

// ─── PIN Key ──────────────────────────────────────────────────────────────────

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
    final Color bg =
        isConfirm
            ? SmartSoleColors.biTeal.withValues(alpha: 0.85)
            : isDelete
            ? SmartSoleColors.biAlert.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05));

    final Color textColor =
        isConfirm
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
