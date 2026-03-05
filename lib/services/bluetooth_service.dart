import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:modar/models/ShoeSample.dart';
import 'package:modar/services/ShoeDataService.dart';
import 'package:permission_handler/permission_handler.dart';

enum ScanStartResult {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  bluetoothNotSupported,
  bluetoothOff,
}

class BleLogEntry {
  final DateTime time;
  final String tag;
  final String message;
  BleLogEntry(this.tag, this.message) : time = DateTime.now();
}

class AppBluetoothService {
  final ShoeDataService shoeDataService;

  AppBluetoothService(this.shoeDataService);

  final Random _random = Random();

  Timer? _simulationTimer;
  int _steps = 0;

  bool _simulationStarted = false;
  bool get isSimulating => _simulationStarted;

  BluetoothDevice? _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  final List<StreamSubscription> _charSubscriptions = [];

  // ── Debug log stream ──────────────────────────────────────────────────────
  final _logController = StreamController<BleLogEntry>.broadcast();
  Stream<BleLogEntry> get logStream => _logController.stream;
  final List<BleLogEntry> logs = [];

  void _log(String tag, String message) {
    final entry = BleLogEntry(tag, message);
    logs.add(entry);
    _logController.add(entry);
    print("[$tag] $message");
  }

  /// Streams exposés
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  /// ------------------------------------------------------
  /// SCAN BLUETOOTH
  /// ------------------------------------------------------

  Future<ScanStartResult> startScan() async {
    _log('SCAN', 'Starting scan sequence');

    if (Platform.isAndroid) {
      final statuses =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

      statuses.forEach((p, s) => _log('PERM', '$p -> $s'));

      if (statuses.values.any((s) => s.isPermanentlyDenied)) {
        _log('PERM', 'Permanently denied');
        return ScanStartResult.permissionPermanentlyDenied;
      }

      if (!statuses.values.every((s) => s.isGranted)) {
        _log('PERM', 'Not all granted');
        return ScanStartResult.permissionDenied;
      }
    }

    if (await FlutterBluePlus.isSupported == false) {
      _log('SCAN', 'Bluetooth not supported');
      return ScanStartResult.bluetoothNotSupported;
    }

    final state = await FlutterBluePlus.adapterState.first;

    if (state != BluetoothAdapterState.on) {
      _log('SCAN', 'Bluetooth off');
      return ScanStartResult.bluetoothOff;
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    _log('SCAN', 'Scan started (15s timeout)');

    return ScanStartResult.success;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// ------------------------------------------------------
  /// CONNECTION DEVICE
  /// ------------------------------------------------------

  Future<void> connect(BluetoothDevice device) async {
    _log('CONN', 'Connecting to ${device.remoteId}...');

    try {
      await device.connect(license: License.free, autoConnect: false);
      _connectedDevice = device;

      _log('CONN', 'Connected successfully');

      final services = await device.discoverServices();
      _log('CONN', '${services.length} services discovered');

      for (final service in services) {
        _log('SVC', 'Service: ${service.uuid}');

        for (final characteristic in service.characteristics) {
          _log('CHR', 'Char: ${characteristic.uuid} props=${characteristic.properties}');

          if (characteristic.properties.notify) {
            _log('CHR', 'Enabling notifications on ${characteristic.uuid}');

            await characteristic.setNotifyValue(true);

            final sub = characteristic.onValueReceived.listen((value) {
              _handleIncomingData(value);
            });
            _charSubscriptions.add(sub);
            _log('CHR', 'Subscribed to ${characteristic.uuid}');
          }
        }
      }
    } catch (e) {
      _log('ERR', 'Connection error: $e');
    }
  }

  /// ------------------------------------------------------
  /// DATA HANDLING
  /// ------------------------------------------------------

  void _handleIncomingData(List<int> value) {
    _log('RAW', '${value.length} bytes: $value');

    // Try JSON first
    try {
      final decoded = utf8.decode(value);
      _log('RAW', 'UTF-8: $decoded');

      final json = jsonDecode(decoded);
      _log('JSON', '$json');

      double p(dynamic v) => double.tryParse(v.toString()) ?? 0.0;

      shoeDataService.addSample(
        ShoeSample(
          steps: json["pas"] ?? 0,
          angleX: p(json["angle_x"]),
          angleY: p(json["angle_y"]),
          badPosition: json["mauvais_positionnement"] ?? false,
          timestamp: DateTime.now(),
          espTimestamp: json["t"],
          distanceM: p(json["distance_m"]),
          ax: p(json["ax"]),
          ay: p(json["ay"]),
          az: p(json["az"]),
          gx: p(json["gx"]),
          gy: p(json["gy"]),
          gz: p(json["gz"]),
          mag: p(json["mag"]),
          delta: p(json["delta"]),
          poidsTalon: p(json["poids_talon_g"]),
          poidsAvantpied: p(json["poids_avantpied_g"]),
        ),
      );

      _log('DATA', 'pas=${json["pas"]} aX=${json["angle_x"]} aY=${json["angle_y"]} gx=${json["gx"]} gy=${json["gy"]} gz=${json["gz"]} mag=${json["mag"]} bad=${json["mauvais_positionnement"]} talon=${json["poids_talon_g"]} avant=${json["poids_avantpied_g"]}');
      return;
    } catch (e) {
      _log('ERR', 'JSON parse: $e');
    }

    // Try binary format: int32 steps | float32 angle_x | float32 angle_y | uint8 bad_pos (13 bytes)
    if (value.length >= 13) {
      try {
        final data = ByteData.sublistView(Uint8List.fromList(value));
        final steps = data.getInt32(0, Endian.little);
        final ax = data.getFloat32(4, Endian.little);
        final ay = data.getFloat32(8, Endian.little);
        final bad = data.getUint8(12) != 0;
        shoeDataService.addSample(
          ShoeSample(
            steps: steps,
            angleX: ax,
            angleY: ay,
            badPosition: bad,
            timestamp: DateTime.now(),
          ),
        );
        _log('BIN', 'Sample added: steps=$steps aX=$ax aY=$ay bad=$bad');
        return;
      } catch (e) {
        _log('ERR', 'Binary parse: $e');
      }
    }

    final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    _log('???', 'Unknown format [${value.length} bytes]: $hex');
  }

  /// ------------------------------------------------------
  /// SIMULATION MODE (DEBUG)
  /// ------------------------------------------------------

  void startRandomSimulation() {
    if (_simulationTimer != null) return;

    _log('SIM', 'Starting random simulation');

    _simulationStarted = true;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _steps += _random.nextInt(2);

      final sample = ShoeSample(
        steps: _steps,
        angleX: 150 + _random.nextDouble() * 20,
        angleY: 140 + _random.nextDouble() * 20,
        badPosition: _random.nextBool(),
        timestamp: DateTime.now(),
      );

      shoeDataService.addSample(sample);
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _simulationStarted = false;
  }

  /// ------------------------------------------------------
  /// DISCONNECT
  /// ------------------------------------------------------

  Future<void> disconnectAll() async {
    stopSimulation();
    for (final sub in _charSubscriptions) {
      await sub.cancel();
    }
    _charSubscriptions.clear();
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    stopSimulation();
    await device.disconnect();
  }

  /// ------------------------------------------------------
  /// CLEANUP
  /// ------------------------------------------------------

  void dispose() {
    disconnectAll();
  }
}
