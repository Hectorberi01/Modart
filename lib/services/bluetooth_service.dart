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

class AppBluetoothService {
  final ShoeDataService shoeDataService;

  AppBluetoothService(this.shoeDataService);

  final Random _random = Random();

  Timer? _simulationTimer;
  int _steps = 0;

  bool _simulationStarted = false;

  BluetoothDevice? _connectedDevice;
  final List<StreamSubscription> _charSubscriptions = [];

  /// Streams exposés
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  /// ------------------------------------------------------
  /// SCAN BLUETOOTH
  /// ------------------------------------------------------

  Future<ScanStartResult> startScan() async {
    print("--- AppBluetoothService: Starting scan sequence ---");

    if (Platform.isAndroid) {
      final statuses =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

      statuses.forEach((p, s) => print("$p -> $s"));

      if (statuses.values.any((s) => s.isPermanentlyDenied)) {
        return ScanStartResult.permissionPermanentlyDenied;
      }

      if (!statuses.values.every((s) => s.isGranted)) {
        return ScanStartResult.permissionDenied;
      }
    }

    if (await FlutterBluePlus.isSupported == false) {
      return ScanStartResult.bluetoothNotSupported;
    }

    final state = await FlutterBluePlus.adapterState.first;

    if (state != BluetoothAdapterState.on) {
      return ScanStartResult.bluetoothOff;
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    return ScanStartResult.success;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// ------------------------------------------------------
  /// CONNECTION DEVICE
  /// ------------------------------------------------------

  Future<void> connect(BluetoothDevice device) async {
    print("--- Connecting to ${device.remoteId} ---");

    try {
      await device.connect(license: License.free, autoConnect: false);
      _connectedDevice = device;

      print("--- Connected successfully ---");

      final services = await device.discoverServices();

      for (final service in services) {
        print("Service found: ${service.uuid}");

        for (final characteristic in service.characteristics) {
          print("Characteristic found: ${characteristic.uuid}");

          if (characteristic.properties.notify) {
            print("Enabling notifications");

            await characteristic.setNotifyValue(true);

            final sub = characteristic.onValueReceived.listen((value) {
              _handleIncomingData(value);
            });
            _charSubscriptions.add(sub);
            //startRandomSimulation();
          }
        }
      }

      //startRandomSimulation();
    } catch (e) {
      print("Connection error: $e");
    }
  }

  /// ------------------------------------------------------
  /// DATA HANDLING
  /// ------------------------------------------------------

  void _handleIncomingData(List<int> value) {
    print("values : $value");

    try {
      final decoded = utf8.decode(value);
      print("decode : $decoded");

      final json = jsonDecode(decoded);
      print("json : $json");

      shoeDataService.addSample(
        ShoeSample(
          steps: json["pas"] ?? 0,
          angleX: double.parse(json["angle_x"].toString()),
          angleY: double.parse(json["angle_y"].toString()),
          badPosition: json["mauvais_positionnement"] ?? false,
          timestamp: DateTime.now(),
        ),
      );

      return;
    } catch (e) {
      print("JSON parse error: $e");
    }

    final hex = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    print("BLE unknown format [${value.length} bytes]: $hex");
  }

  /// ------------------------------------------------------
  /// SIMULATION MODE (DEBUG)
  /// ------------------------------------------------------

  void startRandomSimulation() {
    if (_simulationTimer != null) return;

    print("Starting random simulation");

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
