import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../main.dart' show ThemeProvider;
import '../models/user_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Profil utilisateur & réglages
//
// Avatar avec initiale, infos profil, toggle dark/light, GDPR switches,
// liens export + déconnexion.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user
  final UserProfile _user = const UserProfile(
    id: 1,
    displayName: 'Thomas',
    email: 'thomas@smartsole.io',
    profileType: ProfileType.urban,
    shoeSize: 43,
    consentCloud: true,
    consentAnalytics: true,
    consentPush: false,
  );

  late bool _consentCloud;
  late bool _consentAnalytics;
  late bool _consentPush;

  @override
  void initState() {
    super.initState();
    _consentCloud = _user.consentCloud;
    _consentAnalytics = _user.consentAnalytics;
    _consentPush = _user.consentPush;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return MeshGradientBackground(
      biState: BIState.neutral,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text('Profil', style: textTheme.headlineSmall),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            children: [
              // ── Avatar + Nom ──────────────────────────────────────────
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SmartSoleColors.biNormal, SmartSoleColors.biTeal],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    (_user.displayName ?? 'U')[0].toUpperCase(),
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _user.displayName ?? 'Utilisateur',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(_user.email, style: textTheme.bodySmall),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _profileColor(
                    _user.profileType,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _profileLabel(_user.profileType),
                  style: textTheme.labelSmall?.copyWith(
                    color: _profileColor(_user.profileType),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Préférences ───────────────────────────────────────────
              _SectionHeader(title: 'Préférences', icon: Icons.tune),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _ToggleTile(
                      icon: Icons.dark_mode_outlined,
                      label: 'Mode sombre',
                      value: themeProvider.isDarkMode,
                      onChanged: (v) => themeProvider.setDarkMode(v),
                    ),
                    Divider(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    _InfoTile(
                      icon: Icons.straighten,
                      label: 'Pointure',
                      value: '${_user.shoeSize ?? "Non renseignée"}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── GDPR ──────────────────────────────────────────────────
              _SectionHeader(
                title: 'Consentements RGPD',
                icon: Icons.shield_outlined,
              ),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _ToggleTile(
                      icon: Icons.cloud_outlined,
                      label: 'Sauvegarde cloud',
                      value: _consentCloud,
                      onChanged: (v) => setState(() => _consentCloud = v),
                    ),
                    Divider(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    _ToggleTile(
                      icon: Icons.bar_chart,
                      label: 'Analytics anonymes',
                      value: _consentAnalytics,
                      onChanged: (v) => setState(() => _consentAnalytics = v),
                    ),
                    Divider(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    _ToggleTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications push',
                      value: _consentPush,
                      onChanged: (v) => setState(() => _consentPush = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions ───────────────────────────────────────────────
              _SectionHeader(title: 'Données', icon: Icons.storage_outlined),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.download_outlined,
                      label: 'Exporter mes données (JSON)',
                      onTap: () {
                        // TODO: export
                      },
                    ),
                    Divider(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    _ActionTile(
                      icon: Icons.delete_outline,
                      label: 'Supprimer mon compte',
                      color: SmartSoleColors.biAlert,
                      onTap: () {
                        // TODO: delete
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Version ───────────────────────────────────────────────
              Text(
                'SmartSole MVP v1.0 · © 2026',
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isDark
                          ? SmartSoleColors.textTertiaryDark
                          : SmartSoleColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _profileColor(ProfileType type) {
    return switch (type) {
      ProfileType.urban => SmartSoleColors.biNormal,
      ProfileType.kids => SmartSoleColors.biTeal,
      ProfileType.pro => SmartSoleColors.biNavy,
    };
  }

  String _profileLabel(ProfileType type) {
    return switch (type) {
      ProfileType.urban => 'Actif Urbain',
      ProfileType.kids => 'Parent — Suivi Enfant',
      ProfileType.pro => 'Professionnel Santé',
    };
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              isDark
                  ? SmartSoleColors.textTertiaryDark
                  : SmartSoleColors.textTertiaryLight,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Toggle Tile ────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isDark
                    ? SmartSoleColors.textSecondaryDark
                    : SmartSoleColors.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: SmartSoleColors.biNormal,
            activeTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ─── Info Tile ──────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isDark
                    ? SmartSoleColors.textSecondaryDark
                    : SmartSoleColors.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isDark
                      ? SmartSoleColors.textSecondaryDark
                      : SmartSoleColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile ────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color c =
        color ??
        (isDark
            ? SmartSoleColors.textPrimaryDark
            : SmartSoleColors.textPrimaryLight);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: c.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
