import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onManageBluetooth});
  final VoidCallback onManageBluetooth;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppBluetoothService _bluetoothService = AppBluetoothService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Réglages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(label: 'Bluetooth'),
          StreamBuilder<BluetoothAdapterState>(
            stream: _bluetoothService.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (context, snapshot) {
              final isOn = snapshot.data == BluetoothAdapterState.on;
              return _SettingsTile(
                icon: isOn ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                iconColor: isOn ? Colors.blue : Colors.grey,
                title: 'État du Bluetooth',
                subtitle: isOn ? 'Activé' : 'Désactivé',
                trailing: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? Colors.green : Colors.red.shade300,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.manage_search,
            iconColor: Colors.black,
            title: 'Gérer les appareils',
            subtitle: 'Scanner et connecter une chaussure',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            onTap: widget.onManageBluetooth,
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'À propos'),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.black,
            title: 'Application',
            subtitle: 'Modar v1.0.0',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
