import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/l10n/app_localizations.dart';
import 'package:modar/providers.dart';
import 'package:modar/theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';
import '../models/user_profile.dart';
import 'bluetooth_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsScreen — Merged v1 settings + v4 profile (glassmorphism)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.onManageBluetooth});
  final VoidCallback? onManageBluetooth;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoConnect = true;
  bool _hapticFeedback = true;
  bool _isEditingPersonal = false;

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
    if (_nameCtrl.text.trim().isNotEmpty) fields['displayName'] = _nameCtrl.text.trim();
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
          SnackBar(content: Text(AppLocalizations.of(context).profileSaveError), behavior: SnackBarBehavior.floating),
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
      Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bluetoothService = ref.watch(bluetoothServiceProvider);
    final settings = ref.watch(appSettingsProvider);
    final authState = ref.watch(authProvider);
    final UserProfile? profile = authState.userProfile;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String displayName = profile?.displayName ?? l.profileDefaultName;
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
          title: Text(l.settingsTitle, style: textTheme.headlineSmall),
          centerTitle: true,
          actions: [
            if (!_isEditingPersonal && profile != null)
              IconButton(
                icon: Icon(Icons.edit_outlined, color: SmartSoleColors.biNormal, size: 22),
                tooltip: l.profileEditTooltip,
                onPressed: () {
                  _loadFromProfile();
                  setState(() => _isEditingPersonal = true);
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ══════════════════════════════════════════════════════════════
              // PROFIL UTILISATEUR
              // ══════════════════════════════════════════════════════════════
              const SizedBox(height: 8),
              // Avatar + Nom
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [SmartSoleColors.biNormal, SmartSoleColors.biWarning],
                        ),
                        boxShadow: [
                          BoxShadow(color: SmartSoleColors.biNormal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
                            border: Border.all(color: SmartSoleColors.biNormal.withValues(alpha: 0.4)),
                          ),
                          child: Icon(Icons.edit, size: 12, color: SmartSoleColors.biNormal),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(displayName, style: textTheme.headlineMedium)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(child: Text(email, style: textTheme.bodySmall)),
              ],
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _profileColor(profileType).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _profileLabel(profileType),
                    style: textTheme.labelSmall?.copyWith(color: _profileColor(profileType), fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Informations personnelles
              _SectionHeader(title: l.profilePersonalInfo, icon: Icons.person_outline),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 280),
                crossFadeState: _isEditingPersonal ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                // Mode lecture
                firstChild: GlassBentoCard(
                  child: Column(
                    children: [
                      _InfoTile(icon: Icons.badge_outlined, label: l.profileFirstName, value: displayName),
                      _divider(isDark),
                      _InfoTile(icon: Icons.email_outlined, label: l.profileEmail, value: email.isNotEmpty ? email : '—'),
                      _divider(isDark),
                      _InfoTile(icon: Icons.wc_outlined, label: l.profileGender, value: gender == UserGender.male ? l.profileGenderMale : l.profileGenderFemale),
                      _divider(isDark),
                      _InfoTile(icon: Icons.straighten, label: l.profileShoeSize, value: shoeSize > 0 ? '${shoeSize.toStringAsFixed(0)} EU' : '—'),
                      _divider(isDark),
                      _InfoTile(icon: Icons.monitor_weight_outlined, label: l.profileWeight, value: weightKg > 0 ? '${weightKg.toStringAsFixed(0)} kg' : '—'),
                      _divider(isDark),
                      _InfoTile(icon: Icons.height, label: l.profileHeight, value: heightCm > 0 ? '${heightCm.toStringAsFixed(0)} cm' : '—'),
                    ],
                  ),
                ),
                // Mode édition
                secondChild: GlassBentoCard(
                  child: Column(
                    children: [
                      _EditField(icon: Icons.badge_outlined, label: l.profileFirstName, controller: _nameCtrl),
                      _divider(isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.wc_outlined, size: 18, color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight),
                            const SizedBox(width: 12),
                            Expanded(child: _GenderToggle(value: _editingGender, onChanged: (v) => setState(() => _editingGender = v))),
                          ],
                        ),
                      ),
                      _divider(isDark),
                      _EditField(icon: Icons.straighten, label: l.profileShoeSizeEdit, controller: _shoeSizeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      _divider(isDark),
                      _EditField(icon: Icons.monitor_weight_outlined, label: l.profileWeightEdit, controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      _divider(isDark),
                      _EditField(icon: Icons.height, label: l.profileHeightEdit, controller: _heightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: false), inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelEdit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight,
                                side: BorderSide(color: isDark ? SmartSoleColors.glassBorderDark : SmartSoleColors.glassBorderLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadiusSm)),
                              ),
                              child: Text(l.profileCancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _savePersonalInfo,
                              child: authState.isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(l.profileSave),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════════════
              // BLUETOOTH
              // ══════════════════════════════════════════════════════════════
              _SectionHeader(title: l.settingsBtSection, icon: Icons.bluetooth),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    StreamBuilder<BluetoothAdapterState>(
                      stream: bluetoothService.adapterState,
                      initialData: BluetoothAdapterState.unknown,
                      builder: (context, snapshot) {
                        final isOn = snapshot.data == BluetoothAdapterState.on;
                        return _SettingsTile(
                          icon: isOn ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                          iconColor: isOn ? SmartSoleColors.biSuccess : (isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight),
                          label: 'Bluetooth',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOn ? l.settingsBtEnabled : l.settingsBtDisabled,
                                style: TextStyle(fontSize: 13, color: isOn ? SmartSoleColors.biSuccess : (isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 6),
                              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOn ? SmartSoleColors.biSuccess : Colors.grey.shade400)),
                            ],
                          ),
                        );
                      },
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.bluetooth_searching,
                      iconColor: SmartSoleColors.biNavy,
                      label: l.settingsManageDevices,
                      subtitle: l.settingsManageDevicesSub,
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight, size: 20),
                      onTap: widget.onManageBluetooth ?? () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BluetoothScreen(onContinue: () => Navigator.pop(context))));
                      },
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.wifi_tethering_rounded,
                      iconColor: SmartSoleColors.biAlert,
                      label: l.settingsAutoConnect,
                      trailing: Switch.adaptive(
                        value: _autoConnect,
                        onChanged: (v) => setState(() => _autoConnect = v),
                        activeThumbColor: SmartSoleColors.biNormal,
                        activeTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════════════
              // PRÉFÉRENCES
              // ══════════════════════════════════════════════════════════════
              _SectionHeader(title: l.settingsPrefsSection, icon: Icons.tune),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: SmartSoleColors.biNavy,
                      label: l.settingsTheme,
                      subtitle: _themeLabel(settings.themeMode, l),
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight, size: 20),
                      onTap: () => _showThemePicker(context, settings.themeMode, l),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: SmartSoleColors.biNavy,
                      label: l.settingsLanguage,
                      subtitle: settings.locale.languageCode == 'fr' ? l.settingsLangFr : l.settingsLangEn,
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight, size: 20),
                      onTap: () => _showLanguagePicker(context, l),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.vibration_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      label: l.settingsHaptic,
                      trailing: Switch.adaptive(
                        value: _hapticFeedback,
                        onChanged: (v) => setState(() => _hapticFeedback = v),
                        activeThumbColor: SmartSoleColors.biNormal,
                        activeTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════════════
              // CONSENTEMENTS RGPD
              // ══════════════════════════════════════════════════════════════
              _SectionHeader(title: l.gdprTitle, icon: Icons.shield_outlined),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.cloud_outlined,
                      iconColor: SmartSoleColors.biTeal,
                      label: l.gdprCloud,
                      trailing: Switch.adaptive(
                        value: consentCloud,
                        onChanged: (v) => _updateConsent('consentCloud', v),
                        activeThumbColor: SmartSoleColors.biNormal,
                        activeTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                      ),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.bar_chart,
                      iconColor: SmartSoleColors.biTeal,
                      label: l.gdprAnalytics,
                      trailing: Switch.adaptive(
                        value: consentAnalytics,
                        onChanged: (v) => _updateConsent('consentAnalytics', v),
                        activeThumbColor: SmartSoleColors.biNormal,
                        activeTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                      ),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      iconColor: SmartSoleColors.biTeal,
                      label: l.gdprPush,
                      trailing: Switch.adaptive(
                        value: consentPush,
                        onChanged: (v) => _updateConsent('consentPush', v),
                        activeThumbColor: SmartSoleColors.biNormal,
                        activeTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ══════════════════════════════════════════════════════════════
              // DONNÉES & COMPTE
              // ══════════════════════════════════════════════════════════════
              _SectionHeader(title: l.dataSection, icon: Icons.storage_outlined),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.download_outlined,
                      iconColor: isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight,
                      label: l.dataExport,
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight, size: 20),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.dataExportWip), behavior: SnackBarBehavior.floating));
                      },
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: SmartSoleColors.biWarning,
                      label: l.settingsClearData,
                      subtitle: l.settingsClearDataSub,
                      onTap: () => _confirmClearData(context, l),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.logout,
                      iconColor: SmartSoleColors.biWarning,
                      label: l.dataSignOut,
                      onTap: _signOut,
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.delete_forever_outlined,
                      iconColor: SmartSoleColors.biAlert,
                      label: l.dataDeleteAccount,
                      labelColor: SmartSoleColors.biAlert,
                      onTap: () => _showDeleteConfirm(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── À propos
              _SectionHeader(title: l.settingsAboutSection, icon: Icons.info_outline),
              const SizedBox(height: 10),
              GlassBentoCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight,
                      label: l.settingsVersion,
                      subtitle: 'Modart v1.0.0',
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      iconColor: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight,
                      label: l.settingsLicenses,
                      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight, size: 20),
                      onTap: () => showLicensePage(context: context, applicationName: 'Modart', applicationVersion: '1.0.0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Divider _divider(bool isDark) => Divider(
    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
    height: 1,
  );

  String _themeLabel(ThemeMode mode, AppLocalizations l) {
    switch (mode) {
      case ThemeMode.dark: return l.settingsThemeDark;
      case ThemeMode.system: return l.settingsThemeSystem;
      default: return l.settingsThemeLight;
    }
  }

  Color _profileColor(ProfileType type) => switch (type) {
    ProfileType.urban => SmartSoleColors.biNormal,
    ProfileType.kids => SmartSoleColors.biTeal,
    ProfileType.pro => SmartSoleColors.biNavy,
  };

  String _profileLabel(ProfileType type) {
    final l = AppLocalizations.of(context);
    return switch (type) {
      ProfileType.urban => l.profileTypeUrban,
      ProfileType.kids => l.profileTypeKids,
      ProfileType.pro => l.profileTypePro,
    };
  }

  void _showLanguagePicker(BuildContext context, AppLocalizations l) {
    final current = ref.read(appSettingsProvider).locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.settingsLanguage, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight)),
        children: [
          _dialogOption(context, label: l.settingsLangFr, selected: current.languageCode == 'fr', onTap: () { ref.read(appSettingsProvider.notifier).setLocale(const Locale('fr')); Navigator.pop(context); }),
          _dialogOption(context, label: l.settingsLangEn, selected: current.languageCode == 'en', onTap: () { ref.read(appSettingsProvider.notifier).setLocale(const Locale('en')); Navigator.pop(context); }),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeMode current, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.settingsTheme, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight)),
        children: [
          _dialogOption(context, label: l.settingsThemeLight, selected: current == ThemeMode.light, onTap: () { ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.light); Navigator.pop(context); }),
          _dialogOption(context, label: l.settingsThemeDark, selected: current == ThemeMode.dark, onTap: () { ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.dark); Navigator.pop(context); }),
          _dialogOption(context, label: l.settingsThemeSystem, selected: current == ThemeMode.system, onTap: () { ref.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.system); Navigator.pop(context); }),
        ],
      ),
    );
  }

  Widget _dialogOption(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SimpleDialogOption(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? SmartSoleColors.biNormal : (isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight)))),
          if (selected) const Icon(Icons.check_rounded, color: SmartSoleColors.biNormal, size: 18),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, AppLocalizations l) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.settingsClearDialogTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight)),
        content: Text(l.settingsClearDialogMsg, style: TextStyle(color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.settingsCancel, style: TextStyle(color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(databaseServiceProvider).deleteAllSessions();
              ref.invalidate(sessionsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l.settingsClearedSnack),
                  backgroundColor: SmartSoleColors.biAlert,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            },
            child: Text(l.settingsClearConfirm, style: const TextStyle(color: SmartSoleColors.biAlert)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? SmartSoleColors.darkCard : SmartSoleColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.dataDeleteTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight)),
        content: Text(l.dataDeleteMsg, style: TextStyle(color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.dataDeleteCancel, style: TextStyle(color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SmartSoleColors.biAlert),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.dataDeleteConfirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PARTAGÉS
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.iconColor, required this.label, this.labelColor, this.subtitle, this.trailing, this.onTap});
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: labelColor ?? (isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight), fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: isDark ? SmartSoleColors.textTertiaryDark : SmartSoleColors.textTertiaryLight)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.icon, required this.label, required this.controller, this.keyboardType = TextInputType.text, this.inputFormatters});
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
          Icon(icon, size: 18, color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: 12, color: isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SmartSoleColors.biNormal, width: 1.5)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? SmartSoleColors.glassBorderDark : SmartSoleColors.glassBorderLight)),
              ),
            ),
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
        color: isDark ? SmartSoleColors.darkBg : SmartSoleColors.lightBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GenderChip(label: 'H', selected: value == UserGender.male, icon: Icons.man_outlined, onTap: () => onChanged(UserGender.male)),
          _GenderChip(label: 'F', selected: value == UserGender.female, icon: Icons.woman_outlined, onTap: () => onChanged(UserGender.female)),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({required this.label, required this.selected, required this.icon, required this.onTap});
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
          color: selected ? SmartSoleColors.biNormal.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? SmartSoleColors.biNormal : SmartSoleColors.textSecondaryDark),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: selected ? SmartSoleColors.biNormal : SmartSoleColors.textSecondaryDark, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
