import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/l10n/app_localizations.dart';
import 'package:modar/providers.dart';
import '../services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kAccent = Color(0xFF2F80ED);
const _kSuccess = Color(0xFF27AE60);
const _kDanger = Color(0xFFEB5757);

List<BoxShadow> _cardShadow() => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 20,
    offset: const Offset(0, 4),
  ),
];

class BluetoothScreen extends ConsumerStatefulWidget {
  const BluetoothScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  ConsumerState<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends ConsumerState<BluetoothScreen> {
  late AppBluetoothService _bluetoothService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ScanStartResult? _scanResult;
  final Set<String> _hiddenDeviceIds = {};
  final Map<String, BluetoothConnectionState> _connectionStates = {};
  final Map<String, StreamSubscription<BluetoothConnectionState>>
      _connectionSubs = {};
  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  @override
  void initState() {
    super.initState();
    _bluetoothService = ref.read(bluetoothServiceProvider);
    _startScan();
    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final id = r.device.remoteId.str;
        if (!_connectionSubs.containsKey(id)) {
          _connectionSubs[id] = r.device.connectionState.listen((state) {
            if (mounted) setState(() => _connectionStates[id] = state);
          });
        }
      }
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
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
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l.btTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Adapter state
          StreamBuilder<BluetoothAdapterState>(
            stream: _bluetoothService.adapterState,
            initialData: BluetoothAdapterState.unknown,
            builder: (_, snap) {
              final isOn = snap.data == BluetoothAdapterState.on;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOn
                      ? _kSuccess.withValues(alpha: 0.08)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOn
                        ? _kSuccess.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn ? _kSuccess : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOn ? l.btEnabled : l.btDisabled,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isOn ? _kSuccess : Colors.orange.shade700,
                      ),
                    ),
                    if (!isOn && snap.data != BluetoothAdapterState.unknown) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ph.openAppSettings(),
                        child: Text(
                          l.btEnable,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Permission banner
          if (_scanResult == ScanStartResult.permissionPermanentlyDenied ||
              _scanResult == ScanStartResult.permissionDenied)
            _PermissionBanner(
              permanent:
                  _scanResult == ScanStartResult.permissionPermanentlyDenied,
              onRetry: _startScan,
            ),

          const SizedBox(height: 20),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: l.btSearchHint,
                hintStyle: TextStyle(color: secondaryColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: secondaryColor, size: 20),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kAccent, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.btDetectedDevices,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                StreamBuilder<bool>(
                  stream: _bluetoothService.isScanning,
                  initialData: false,
                  builder: (_, snap) {
                    if (snap.data == true) {
                      return const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kAccent),
                      );
                    }
                    return GestureDetector(
                      onTap: _startScan,
                      child: Row(
                        children: [
                          const Icon(Icons.refresh, size: 14, color: _kAccent),
                          const SizedBox(width: 4),
                          Text(
                            l.btRefresh,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // List
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: _bluetoothService.scanResults,
              initialData: const [],
              builder: (_, snap) {
                final all = snap.data ?? [];
                final results = all
                    .where((r) {
                      if (_hiddenDeviceIds.contains(r.device.remoteId.str)) {
                        return false;
                      }
                      if (_searchQuery.isEmpty) return true;
                      return r.device.platformName
                          .toLowerCase()
                          .contains(_searchQuery);
                    })
                    .toList()
                  ..sort((a, b) {
                    final aC = _connectionStates[a.device.remoteId.str] ==
                        BluetoothConnectionState.connected;
                    final bC = _connectionStates[b.device.remoteId.str] ==
                        BluetoothConnectionState.connected;
                    if (aC && !bC) return -1;
                    if (!aC && bC) return 1;
                    return 0;
                  });

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_searching,
                            size: 48,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
                        Text(
                          l.btNoDevice,
                          style: TextStyle(color: secondaryColor, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final r = results[i];
                    final name = r.device.platformName.isNotEmpty
                        ? r.device.platformName
                        : l.btUnknownDevice;
                    final id = r.device.remoteId.str;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            setState(() => _hiddenDeviceIds.add(id)),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: _kDanger,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 22),
                        ),
                        child: _DeviceCard(
                          name: name,
                          device: r.device,
                          rssi: r.rssi,
                          service: _bluetoothService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            child: Column(
              children: [
                Text(
                  l.btShoeInstruction,
                  style: TextStyle(color: secondaryColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l.btContinue,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
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

// ─── Permission Banner ────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.permanent, required this.onRetry});
  final bool permanent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFF92400E), size: 15),
              const SizedBox(width: 7),
              Text(
                l.btPermissionsDenied,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            permanent ? l.btEnableInSettings : l.btPermissionsNeeded,
            style: const TextStyle(
                color: Color(0xFF92400E), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: permanent ? () => ph.openAppSettings() : onRetry,
            child: Text(
              permanent ? l.btOpenSettings : l.btRetry,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Device Card ──────────────────────────────────────────────────────────────

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
  late final StreamSubscription<BluetoothConnectionState> _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.device.connectionState.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case BluetoothConnectionState.connected:
            _status = DeviceStatus.connected;
          case BluetoothConnectionState.connecting:
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
    _sub.cancel();
    super.dispose();
  }

  double get _rssiPercent => ((widget.rssi + 100) / 70).clamp(0.0, 1.0);

  Color get _rssiColor {
    if (_rssiPercent > 0.65) return _kSuccess;
    if (_rssiPercent > 0.35) return const Color(0xFFF59E0B);
    return _kDanger;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final isConnected = _status == DeviceStatus.connected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConnected
              ? _kSuccess.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: _cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isConnected
                      ? _kSuccess.withValues(alpha: 0.1)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_walk,
                    size: 20,
                    color: isConnected ? _kSuccess : secondaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(widget.device.remoteId.str,
                        style: TextStyle(color: secondaryColor, fontSize: 11)),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 11, color: _kSuccess),
                      const SizedBox(width: 3),
                      Text(l.btConnected,
                          style: const TextStyle(
                              color: _kSuccess,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(l.btSignal,
                  style: TextStyle(color: secondaryColor, fontSize: 11)),
              const Spacer(),
              Text('${widget.rssi} dBm',
                  style: TextStyle(color: secondaryColor, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _rssiPercent,
              minHeight: 4,
              backgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_rssiColor),
            ),
          ),
          const SizedBox(height: 14),
          _ActionButton(
            status: _status,
            onConnect: () => widget.service.connect(widget.device),
            onDisconnect: () => widget.service.disconnect(widget.device),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.status,
    required this.onConnect,
    required this.onDisconnect,
  });
  final DeviceStatus status;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    switch (status) {
      case DeviceStatus.disconnected:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.btConnect,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      case DeviceStatus.connecting:
        return Container(
          width: double.infinity,
          height: 42,
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kAccent),
              ),
              const SizedBox(width: 10),
              Text(l.btConnecting,
                  style: const TextStyle(
                      color: _kAccent,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ],
          ),
        );
      case DeviceStatus.connected:
        return SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: onDisconnect,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: BorderSide(color: _kDanger.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.btDisconnect,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        );
      case DeviceStatus.outOfRange:
        return Container(
          width: double.infinity,
          height: 42,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(l.btOutOfRange,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13)),
          ),
        );
    }
  }
}
