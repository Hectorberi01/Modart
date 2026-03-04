import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen v1 — Authentification Profile-Aware
//
// L'écran de connexion s'adapte selon le profil sélectionné à l'onboarding :
//
//   • Urban   → Connexion email/password classique
//   • Kids    → PIN Parent 4 chiffres (protection enfant)
//   • Pro     → Connexion identifiant professionnel + code cabinet
//
// Sur succès : navigation vers HomeShell avec le ProfileType en argument.
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

  // PIN for kids mode
  final List<String> _pinDigits = ['', '', '', ''];
  int _pinCursor = 0;

  bool _loading = false;
  bool _obscurePass = true;
  String? _errorMsg;

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

  // ── Simulate async auth ──────────────────────────────────────────────────

  Future<void> _authenticate() async {
    setState(() {
      _errorMsg = null;
      _loading = true;
    });

    // Simulate network delay (400ms)
    await Future.delayed(const Duration(milliseconds: 400));

    // Mock validation
    bool valid = false;
    switch (_type) {
      case ProfileType.urban:
        valid = _emailCtrl.text.contains('@') && _passCtrl.text.length >= 4;
        break;
      case ProfileType.kids:
        valid = _pinDigits.join() == '1234' || _pinDigits.join().length == 4;
        break;
      case ProfileType.pro:
        valid =
            _emailCtrl.text.contains('@') &&
            _passCtrl.text.length >= 4 &&
            _proCodeCtrl.text.isNotEmpty;
        break;
    }

    if (!mounted) return;

    if (valid) {
      // ── Navigate to home with profile context ──────────────────────────
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home', (route) => false, arguments: _type);
    } else {
      setState(() {
        _loading = false;
        _errorMsg =
            _type == ProfileType.kids
                ? 'Code incorrect. Essayez 1234 pour la démo.'
                : 'Identifiants incorrects. Vérifiez vos informations.';
      });
      HapticFeedback.mediumImpact();
    }
  }

  // ── PIN digit tap (kids mode) ─────────────────────────────────────────────

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

  void _onPinConfirm() {
    if (_pinCursor < 4) return;
    _authenticate();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient mesh
          Positioned.fill(child: _BackgroundMesh(isDark: isDark)),

          // Content
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
                        _buildHeader(textTheme, isDark),
                        const SizedBox(height: 36),
                        _buildFormCard(textTheme, isDark),
                        const SizedBox(height: 20),
                        if (_errorMsg != null) _buildError(),
                        const SizedBox(height: 24),
                        _buildAuthButton(textTheme, isDark),
                        const SizedBox(height: 32),
                        _buildFooter(textTheme, isDark),
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

  // ── Header Section ───────────────────────────────────────────────────────

  Widget _buildHeader(TextTheme tt, bool isDark) {
    final (icon, title, sub) = switch (_type) {
      ProfileType.urban => (
        Icons.directions_walk,
        'Bon retour, ${widget.profile.displayName ?? widget.profile.email}',
        'Connectez-vous pour accéder à votre analyse de marche.',
      ),
      ProfileType.kids => (
        Icons.child_care,
        'Espace Parent',
        'Entrez votre code PIN pour accéder au suivi de ${widget.profile.childProfile?.nickname ?? "votre enfant"}.',
      ),
      ProfileType.pro => (
        Icons.local_hospital_outlined,
        'Espace Clinicien',
        'Connexion sécurisée pour professionnels de santé.',
      ),
    };

    return Column(
      children: [
        // Logo + icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SmartSoleColors.heroGradient,
            boxShadow: [
              BoxShadow(
                color: SmartSoleColors.biTeal.withValues(alpha: 0.30),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 34),
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

  // ── Form Card ───────────────────────────────────────────────────────────

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
            ProfileType.kids => _buildPinPad(isDark),
            ProfileType.pro => _buildProForm(isDark),
          },
        ),
      ),
    );
  }

  // ── Urban: Email + Password ────────────────────────────────────────────

  Widget _buildEmailForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _InputField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'thomas@smartsole.io',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _passCtrl,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            isDark: isDark,
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
              onPressed: () {},
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

  // ── Kids: PIN Pad ─────────────────────────────────────────────────────

  Widget _buildPinPad(bool isDark) {
    return Column(
      children: [
        // PIN display
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
        // Number grid
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

  // ── Pro: Email + Password + Cabinet code ─────────────────────────────

  Widget _buildProForm(bool isDark) {
    return Column(
      children: [
        _InputField(
          controller: _emailCtrl,
          label: 'Email professionnel',
          hint: 'dr.amara@cabinet.fr',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _passCtrl,
          label: 'Mot de passe',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscure: _obscurePass,
          isDark: isDark,
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
        _InputField(
          controller: _proCodeCtrl,
          label: 'Code cabinet',
          hint: 'ex: CAB-2026',
          icon: Icons.local_hospital_outlined,
          isDark: isDark,
        ),
      ],
    );
  }

  // ── Error Banner ──────────────────────────────────────────────────────

  Widget _buildError() {
    return AnimatedOpacity(
      opacity: _errorMsg != null ? 1 : 0,
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
            Icon(Icons.error_outline, size: 16, color: SmartSoleColors.biAlert),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMsg ?? '',
                style: TextStyle(fontSize: 13, color: SmartSoleColors.biAlert),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Auth Button ───────────────────────────────────────────────────────

  Widget _buildAuthButton(TextTheme tt, bool isDark) {
    // Kids: PIN confirm is inside the pad itself
    if (_type == ProfileType.kids) return const SizedBox.shrink();

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
          onTap: _loading ? null : _authenticate,
          child: Center(
            child:
                _loading
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
  }

  // ── Footer ────────────────────────────────────────────────────────────

  Widget _buildFooter(TextTheme tt, bool isDark) {
    return Column(
      children: [
        Text(
          'Données protégées — conformité RGPD',
          style: TextStyle(
            fontSize: 11,
            color:
                isDark
                    ? SmartSoleColors.textTertiaryDark
                    : SmartSoleColors.textTertiaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 12,
              color:
                  isDark
                      ? SmartSoleColors.textTertiaryDark
                      : SmartSoleColors.textTertiaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              'SmartSole © 2026 · MVP v1.0',
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark
                        ? SmartSoleColors.textTertiaryDark
                        : SmartSoleColors.textTertiaryLight,
              ),
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
          // Teal glow top-left
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
          // Emerald glow bottom-right
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

// ─── Input Field ─────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;

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

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
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
      ),
    );
  }
}

// ─── PIN Key (numpad) ────────────────────────────────────────────────────────

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
