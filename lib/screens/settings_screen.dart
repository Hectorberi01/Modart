import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/providers.dart';
//import '../services/bluetooth_service.dart';

const _kPrimary = Color(0xFF1C1F2E);
const _kAccent = Color(0xFF2F80ED);
const _kSuccess = Color(0xFF27AE60);
const _kDanger = Color(0xFFEB5757);
const _kBg = Color(0xFFF7F8FA);
const _kTextSecondary = Color(0xFF6B7280);

List<BoxShadow> _cardShadow() => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 20,
    offset: const Offset(0, 4),
  ),
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.onManageBluetooth});
  final VoidCallback onManageBluetooth;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  //final AppBluetoothService _bluetoothService = AppBluetoothService();
  bool _autoConnect = true;
  bool _hapticFeedback = true;

  @override
  Widget build(BuildContext context) {
    final bluetoothService = ref.watch(bluetoothServiceProvider);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        centerTitle: true,
        title: const Text(
          'Réglages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _SectionLabel(label: 'Bluetooth'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              StreamBuilder<BluetoothAdapterState>(
                stream: bluetoothService.adapterState,
                initialData: BluetoothAdapterState.unknown,
                builder: (context, snapshot) {
                  final isOn = snapshot.data == BluetoothAdapterState.on;
                  return _SettingsRow(
                    icon:
                        isOn
                            ? Icons.bluetooth_connected_rounded
                            : Icons.bluetooth_disabled_rounded,
                    iconBg:
                        isOn
                            ? _kSuccess.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.10),
                    iconColor: isOn ? _kSuccess : _kTextSecondary,
                    title: 'Bluetooth',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOn ? 'Activé' : 'Désactivé',
                          style: TextStyle(
                            fontSize: 13,
                            color: isOn ? _kSuccess : _kTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOn ? _kSuccess : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
              _SettingsRow(
                icon: Icons.devices_rounded,
                iconBg: _kAccent.withValues(alpha: 0.10),
                iconColor: _kAccent,
                title: 'Gérer les appareils',
                subtitle: 'Scanner et connecter une chaussure',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 20,
                ),
                onTap: widget.onManageBluetooth,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
              _SettingsRow(
                icon: Icons.wifi_tethering_rounded,
                iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                iconColor: const Color(0xFFF59E0B),
                title: 'Connexion automatique',
                trailing: Switch(
                  value: _autoConnect,
                  onChanged: (v) => setState(() => _autoConnect = v),
                  activeColor: _kAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Préférences'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.vibration_rounded,
                iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                iconColor: const Color(0xFF8B5CF6),
                title: 'Retour haptique',
                trailing: Switch(
                  value: _hapticFeedback,
                  onChanged: (v) => setState(() => _hapticFeedback = v),
                  activeColor: _kAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
              _SettingsRow(
                icon: Icons.language_rounded,
                iconBg: _kAccent.withValues(alpha: 0.10),
                iconColor: _kAccent,
                title: 'Langue',
                subtitle: 'Français',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 20,
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
              _SettingsRow(
                icon: Icons.straighten_rounded,
                iconBg: _kSuccess.withValues(alpha: 0.10),
                iconColor: _kSuccess,
                title: 'Unités',
                subtitle: 'Métrique (km, kg)',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'À propos'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                iconBg: _kPrimary.withValues(alpha: 0.08),
                iconColor: _kPrimary,
                title: 'Version',
                subtitle: 'SmartStep v1.0.0',
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
              _SettingsRow(
                icon: Icons.description_outlined,
                iconBg: _kPrimary.withValues(alpha: 0.08),
                iconColor: _kPrimary,
                title: 'Licences open source',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsCard(
            children: [
              _SettingsRow(
                icon: Icons.delete_outline_rounded,
                iconBg: _kDanger.withValues(alpha: 0.08),
                iconColor: _kDanger,
                title: 'Effacer les données',
                titleColor: _kDanger,
                subtitle: 'Supprimer toutes les sessions',
                onTap: () => _confirmReset(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Effacer les données',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Toutes les sessions seront supprimées définitivement.\nCette action est irréversible.',
              style: TextStyle(color: _kTextSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(databaseServiceProvider).deleteAllSessions();
                  ref.invalidate(sessionsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Toutes les sessions ont été supprimées.'),
                        backgroundColor: _kDanger,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
                child: const Text('Effacer', style: TextStyle(color: _kDanger)),
              ),
            ],
          ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kTextSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _cardShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: titleColor ?? _kPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
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
