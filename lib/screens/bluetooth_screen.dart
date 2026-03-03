import 'dart:async';
import 'package:flutter/material.dart';

import '../services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final AppBluetoothService _bluetoothService = AppBluetoothService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ScanStartResult? _scanResult;
  final Set<String> _hiddenDeviceIds = {};
  final Map<String, BluetoothConnectionState> _connectionStates = {};
  final Map<String, StreamSubscription<BluetoothConnectionState>> _connectionSubs = {};
  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  @override
  void initState() {
    super.initState();
    _startScan();
    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final id = result.device.remoteId.str;
        if (!_connectionSubs.containsKey(id)) {
          _connectionSubs[id] = result.device.connectionState.listen((state) {
            if (mounted) setState(() => _connectionStates[id] = state);
          });
        }
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _startScan() async {
    final result = await _bluetoothService.startScan();
    if (mounted) setState(() => _scanResult = result);
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    _searchController.dispose();
    _scanResultsSub?.cancel();
    for (final sub in _connectionSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Connexion Bluetooth',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          StreamBuilder<BluetoothAdapterState>(
            stream: _bluetoothService.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final isOn = state == BluetoothAdapterState.on;
              return Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: isOn ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F7),
                    child: Icon(
                      isOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                      color: isOn ? Colors.blue : Colors.grey,
                      size: 30,
                    ),
                  ),
                  if (!isOn && state != BluetoothAdapterState.unknown)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton(
                        onPressed: () => ph.openAppSettings(),
                        child: const Text(
                          'Activer le Bluetooth / Paramètres',
                          style: TextStyle(color: Colors.redAccent, fontSize: 13, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_scanResult == ScanStartResult.permissionPermanentlyDenied ||
              _scanResult == ScanStartResult.permissionDenied)
            _PermissionBanner(
              permanent: _scanResult == ScanStartResult.permissionPermanentlyDenied,
              onRetry: _startScan,
            ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des appareils',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appareils détectés à proximité',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                StreamBuilder<bool>(
                  stream: _bluetoothService.isScanning,
                  initialData: false,
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                      onPressed: _startScan,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: _bluetoothService.scanResults,
              initialData: const [],
              builder: (context, snapshot) {
                final allResults = snapshot.data ?? [];
                final results = allResults.where((r) {
                  if (_hiddenDeviceIds.contains(r.device.remoteId.str)) return false;
                  if (_searchQuery.isEmpty) return true;
                  return r.device.platformName.toLowerCase().contains(_searchQuery);
                }).toList()
                  ..sort((a, b) {
                    final aConnected = _connectionStates[a.device.remoteId.str] ==
                        BluetoothConnectionState.connected;
                    final bConnected = _connectionStates[b.device.remoteId.str] ==
                        BluetoothConnectionState.connected;
                    if (aConnected && !bConnected) return -1;
                    if (!aConnected && bConnected) return 1;
                    return 0;
                  });

                if (results.isEmpty) {
                  return const Center(
                    child: Text('Aucun appareil trouvé', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final deviceName = result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : 'Appareil inconnu';
                    final deviceId = result.device.remoteId.str;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(deviceId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => setState(() => _hiddenDeviceIds.add(deviceId)),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                        ),
                        child: _DeviceCard(
                          name: deviceName,
                          device: result.device,
                          rssi: result.rssi,
                          service: _bluetoothService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Assurez-vous que le Bluetooth est activé\net que la chaussure est allumée',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.permanent, required this.onRetry});
  final bool permanent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 18),
              SizedBox(width: 8),
              Text(
                'Permissions Bluetooth refusées',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF856404), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            permanent
                ? 'Les permissions ont été refusées définitivement. Activez-les manuellement dans les Réglages iOS.'
                : 'Les permissions Bluetooth et Localisation sont nécessaires pour scanner les appareils.',
            style: const TextStyle(color: Color(0xFF856404), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: permanent ? () => ph.openAppSettings() : onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF856404),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                permanent ? 'Ouvrir les Réglages' : 'Réessayer',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DeviceStatus { disconnected, connecting, connected, outOfRange }

class _DeviceCard extends StatefulWidget {
  const _DeviceCard({
    required this.name,
    required this.device,
    required this.rssi,
    required this.service,
  });

  final String name;
  final BluetoothDevice device;
  final int rssi;
  final AppBluetoothService service;

  @override
  State<_DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<_DeviceCard> {
  DeviceStatus _status = DeviceStatus.disconnected;
  late final StreamSubscription<BluetoothConnectionState> _connectionSub;

  @override
  void initState() {
    super.initState();
    _connectionSub = widget.device.connectionState.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case BluetoothConnectionState.connected:
            _status = DeviceStatus.connected;
          case BluetoothConnectionState.connecting:
            _status = DeviceStatus.connecting;
          case BluetoothConnectionState.disconnecting:
            _status = DeviceStatus.connecting;
          case BluetoothConnectionState.disconnected:
            _status = DeviceStatus.disconnected;
        }
      });
    });
  }

  @override
  void dispose() {
    _connectionSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfRange = _status == DeviceStatus.outOfRange;

    return Opacity(
      opacity: isOutOfRange ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(20),
          border: _status == DeviceStatus.connected
              ? Border.all(color: Colors.black.withOpacity(0.05))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk, color: Colors.black54, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'ID: ${widget.device.remoteId.str}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _status == DeviceStatus.connected
                        ? Colors.black
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SignalIndicator(rssi: widget.rssi),
                const SizedBox(width: 12),
                Text(
                  '${widget.rssi} dBm',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DeviceActionButton(
              status: _status,
              onConnect: () => widget.service.connect(widget.device),
              onDisconnect: () => widget.service.disconnect(widget.device),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalIndicator extends StatelessWidget {
  const _SignalIndicator({required this.rssi});
  final int rssi;

  int get _bars {
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final activeBars = _bars;
    return Row(
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: 8 + (index * 3),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: index < activeBars
                ? Colors.black
                : Colors.black.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}

class _DeviceActionButton extends StatelessWidget {
  const _DeviceActionButton({
    required this.status,
    required this.onConnect,
    required this.onDisconnect,
  });
  final DeviceStatus status;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DeviceStatus.disconnected:
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Connecter', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      case DeviceStatus.connecting:
        return Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
              ),
              SizedBox(width: 12),
              Text('Connexion...', style: TextStyle(color: Colors.black54)),
            ],
          ),
        );
      case DeviceStatus.connected:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.black, size: 18),
                  SizedBox(width: 8),
                  Text('Connecté avec succès', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onDisconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.05),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Déconnecter'),
              ),
            ),
          ],
        );
      case DeviceStatus.outOfRange:
        return Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Hors de portée', style: TextStyle(color: Colors.black38)),
          ),
        );
    }
  }
}
