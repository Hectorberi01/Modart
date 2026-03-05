import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../models/user_profile.dart';
import '../providers.dart';
import 'bluetooth_screen.dart';

// ProfileScreen — Profil utilisateur & infos personnelles

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditingPersonal = false;

  // Genre sélectionné pendant l'édition
  UserGender _editingGender = UserGender.male;

  late TextEditingController _nameCtrl;
  late TextEditingController _shoeSizeCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _shoeSizeCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProfile());
  }

  void _loadFromProfile() {
    final profile = ref.read(authProvider).userProfile;
    if (profile == null || !mounted) return;
    setState(() {
      _nameCtrl.text = profile.displayName ?? '';
      _shoeSizeCtrl.text = profile.shoeSize?.toStringAsFixed(0) ?? '';
      _weightCtrl.text = profile.weightKg?.toStringAsFixed(0) ?? '';
      _heightCtrl.text = profile.heightCm?.toStringAsFixed(0) ?? '';
      _editingGender = profile.gender ?? UserGender.male;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shoeSizeCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePersonalInfo() async {
    final auth = ref.read(authProvider.notifier);
    final profile = ref.read(authProvider).userProfile;
    if (profile == null) return;

    final fields = <String, dynamic>{};
    if (_nameCtrl.text.trim().isNotEmpty) {
      fields['displayName'] = _nameCtrl.text.trim();
    }
    if (_shoeSizeCtrl.text.isNotEmpty) {
      final v = double.tryParse(_shoeSizeCtrl.text);
      if (v != null) fields['shoeSize'] = v;
    }
    if (_weightCtrl.text.isNotEmpty) {
      final v = double.tryParse(_weightCtrl.text);
      if (v != null) fields['weightKg'] = v;
    }
    if (_heightCtrl.text.isNotEmpty) {
      final v = double.tryParse(_heightCtrl.text);
      if (v != null) fields['heightCm'] = v;
    }
    fields['gender'] = _editingGender.name;

    final ok = await auth.updateProfile(fields);
    if (mounted) {
      setState(() => _isEditingPersonal = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    _loadFromProfile();
    setState(() => _isEditingPersonal = false);
  }

  Future<void> _updateConsent(String key, bool value) async {
    await ref.read(authProvider.notifier).updateProfile({key: value});
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/onboarding', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final UserProfile? profile = authState.userProfile;

    final String displayName = profile?.displayName ?? 'Utilisateur';
    final String email = profile?.email ?? '';
    final ProfileType profileType = profile?.profileType ?? ProfileType.urban;
    final UserGender gender = profile?.gender ?? UserGender.male;
    final double shoeSize = profile?.shoeSize ?? 0;
    final double weightKg = profile?.weightKg ?? 0;
    final double heightCm = profile?.heightCm ?? 0;
    final bool consentCloud = profile?.consentCloud ?? false;
    final bool consentAnalytics = profile?.consentAnalytics ?? false;
    final bool consentPush = profile?.consentPush ?? false;

    return MeshGradientBackground(
      biState: BIState.neutral,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text('Profil', style: textTheme.headlineSmall),
          centerTitle: true,
          actions: [
            if (!_isEditingPersonal)
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: SmartSoleColors.biNormal,
                  size: 22,
                ),
                tooltip: 'Modifier le profil',
                onPressed: () {
                  _loadFromProfile();
                  setState(() => _isEditingPersonal = true);
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar + Nom
              const SizedBox(height: 8),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
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
                              alpha: 0.35,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (!_isEditingPersonal)
                      GestureDetector(
                        onTap: () {
                          _loadFromProfile();
                          setState(() => _isEditingPersonal = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark
                                    ? SmartSoleColors.darkCard
                                    : SmartSoleColors.lightSurface,
                            border: Border.all(
                              color: SmartSoleColors.biNormal.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: SmartSoleColors.biNormal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(child: Text(displayName, style: textTheme.headlineMedium)),
              const SizedBox(height: 4),
              Center(child: Text(email, style: textTheme.bodySmall)),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _profileColor(profileType).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profileLabel(profileType),
                    style: textTheme.labelSmall?.copyWith(
                      color: _profileColor(profileType),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Infos personnelles
              _SectionHeader(
                title: 'Informations personnelles',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 280),
                crossFadeState:
                    _isEditingPersonal
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                // Mode lecture
                firstChild: GlassBentoCard(
                  child: Column(
                    children: [
                      _InfoTile(
                        icon: Icons.badge_outlined,
                        label: 'Prénom',
                        value: displayName,
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.wc_outlined,
                        label: 'Genre',
                        value: gender == UserGender.male ? 'Homme' : 'Femme',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.straighten,
                        label: 'Pointure',
                        value:
                            shoeSize > 0
                                ? '${shoeSize.toStringAsFixed(0)} EU'
                                : '—',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Poids',
                        value:
                            weightKg > 0
                                ? '${weightKg.toStringAsFixed(0)} kg'
                                : '—',
                      ),
                      _divider(isDark),
                      _InfoTile(
                        icon: Icons.height,
                        label: 'Taille',
                        value:
                            heightCm > 0
                                ? '${heightCm.toStringAsFixed(0)} cm'
                                : '—',
                      ),
                    ],
                  ),
                ),
                // Mode édition
                secondChild: GlassBentoCard(
                  child: Column(
                    children: [
                      _EditField(
                        icon: Icons.badge_outlined,
                        label: 'Prénom',
                        controller: _nameCtrl,
                      ),
                      _divider(isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wc_outlined,
                              size: 18,
                              color:
                                  isDark
                                      ? SmartSoleColors.textSecondaryDark
                                      : SmartSoleColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GenderToggle(
                                value: _editingGender,
                                onChanged: (v) {
                                  setState(() {
                                    _editingGender = v;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      _divider(isDark),
                      _EditField(
                        icon: Icons.straighten,
                        label: 'Pointure (EU)',
                        controller: _shoeSizeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _divider(isDark),
                      _EditField(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Poids (kg)',
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      _divider(isDark),
                      _EditField(
                        icon: Icons.height,
                        label: 'Taille (cm)',
                        controller: _heightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Boutons Sauvegarder / Annuler
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    isDark
                                        ? SmartSoleColors.textSecondaryDark
                                        : SmartSoleColors.textSecondaryLight,
                                side: BorderSide(
                                  color:
                                      isDark
                                          ? SmartSoleColors.glassBorderDark
                                          : SmartSoleColors.glassBorderLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    SmartSoleDesign.borderRadiusSm,
                                  ),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  authState.isLoading ? null : _savePersonalInfo,
                              child:
                                  authState.isLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Sauvegarder'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Type de profil
              _SectionHeader(
                title: 'Type de profil',
                icon: Icons.groups_outlined,
              ),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _profileColor(
                          profileType,
                        ).withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        _profileIcon(profileType),
                        size: 20,
                        color: _profileColor(profileType),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profileLabel(profileType),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: _profileColor(profileType),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Défini durant l'onboarding",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Appareils
              const _SectionHeader(title: 'Appareils', icon: Icons.bluetooth),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.bluetooth_searching,
                      label: 'Gérer la connexion',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => BluetoothScreen(
                                  onContinue: () => Navigator.pop(context),
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Préférences
              const _SectionHeader(title: 'Préférences', icon: Icons.tune),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: _ToggleTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Mode sombre',
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (v) {
                    // Theme is handled by the app theme; no-op or implement via a theme provider if needed
                  },
                ),
              ),
              const SizedBox(height: 20),
              // RGPD
              const _SectionHeader(
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
                      value: consentCloud,
                      onChanged: (v) => _updateConsent('consentCloud', v),
                    ),
                    _divider(isDark),
                    _ToggleTile(
                      icon: Icons.bar_chart,
                      label: 'Analytics anonymes',
                      value: consentAnalytics,
                      onChanged: (v) => _updateConsent('consentAnalytics', v),
                    ),
                    _divider(isDark),
                    _ToggleTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications push',
                      value: consentPush,
                      onChanged: (v) => _updateConsent('consentPush', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Données
              _SectionHeader(title: 'Données', icon: Icons.storage_outlined),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.download_outlined,
                      label: 'Exporter mes données (JSON)',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export en cours de développement'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _divider(isDark),
                    _ActionTile(
                      icon: Icons.logout,
                      label: 'Se déconnecter',
                      color: SmartSoleColors.biWarning,
                      onTap: _signOut,
                    ),
                    _divider(isDark),
                    _ActionTile(
                      icon: Icons.delete_outline,
                      label: 'Supprimer mon compte',
                      color: SmartSoleColors.biAlert,
                      onTap: () {
                        _showDeleteConfirm(context, textTheme);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Version
              Center(
                child: Text(
                  'Modart MVP v1.0',
                  style: textTheme.labelSmall?.copyWith(
                    color:
                        isDark
                            ? SmartSoleColors.textTertiaryDark
                            : SmartSoleColors.textTertiaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers

  Divider _divider(bool isDark) => Divider(
    color:
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
    height: 1,
  );

  Color _profileColor(ProfileType type) => switch (type) {
    ProfileType.urban => SmartSoleColors.biNormal,
    ProfileType.kids => SmartSoleColors.biTeal,
    ProfileType.pro => SmartSoleColors.biNavy,
  };

  String _profileLabel(ProfileType type) => switch (type) {
    ProfileType.urban => 'Actif Urbain',
    ProfileType.kids => 'Parent – Suivi Enfant',
    ProfileType.pro => 'Professionnel Santé',
  };

  IconData _profileIcon(ProfileType type) => switch (type) {
    ProfileType.urban => Icons.directions_run,
    ProfileType.kids => Icons.child_care,
    ProfileType.pro => Icons.medical_services_outlined,
  };

  void _showDeleteConfirm(BuildContext context, TextTheme textTheme) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Supprimer le compte ?'),
            content: const Text(
              'Cette action est irréversible. Toutes vos données seront effacées définitivement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartSoleColors.biAlert,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({required this.value, required this.onChanged});
  final UserGender value;
  final ValueChanged<UserGender> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? SmartSoleColors.darkBg
                : SmartSoleColors.lightBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GenderChip(
            label: 'H',
            selected: value == UserGender.male,
            icon: Icons.man_outlined,
            onTap: () => onChanged(UserGender.male),
          ),
          _GenderChip(
            label: 'F',
            selected: value == UserGender.female,
            icon: Icons.woman_outlined,
            onTap: () => onChanged(UserGender.female),
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected
                  ? SmartSoleColors.biNormal.withValues(alpha: 0.18)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  selected
                      ? SmartSoleColors.biNormal
                      : SmartSoleColors.textSecondaryDark,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    selected
                        ? SmartSoleColors.biNormal
                        : SmartSoleColors.textSecondaryDark,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Field ─────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  const _EditField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color:
                      isDark
                          ? SmartSoleColors.textSecondaryDark
                          : SmartSoleColors.textSecondaryLight,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: SmartSoleColors.biNormal,
                    width: 1.5,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        isDark
                            ? SmartSoleColors.glassBorderDark
                            : SmartSoleColors.glassBorderLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            activeThumbColor: SmartSoleColors.biNormal,
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
