import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
  // Singleton
  static final AppBluetoothService _instance = AppBluetoothService._internal();
  factory AppBluetoothService() => _instance;
  AppBluetoothService._internal();

  // Services
  final ShoeDataService _shoeDataService = ShoeDataService();
  final Random _random = Random();
  Timer? _simulationTimer;
  int _steps = 0;

  Stream<ShoeSample> get shoeStream => _shoeDataService.stream;

  // Observable state
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

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

    //iOS : ne demande PAS Permission.bluetooth ici

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

  /*Future<void> connect(BluetoothDevice device) async {
    print("--- AppBluetoothService: Connecting to ${device.remoteId} ---");
    try {
      await device.connect(license: License.free, autoConnect: false);
      print("--- AppBluetoothService: Successfully connected ---");
    } catch (e) {
      print("--- AppBluetoothService: Connection error: $e ---");
    }
  }*/

  Future<void> connect(BluetoothDevice device) async {
    print("--- Connecting to ${device.remoteId} ---");

    try {
      await device.connect(license: License.free, autoConnect: false);

      print("--- Connected successfully ---");

      // 🔥 Découverte des services
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        print("Service found: ${service.uuid}");

        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          print("Characteristic found: ${characteristic.uuid}");

          // Si la caractéristique supporte notifications
          if (characteristic.properties.notify) {
            print("Enabling notifications on ${characteristic.uuid}");

            await characteristic.setNotifyValue(true);

            characteristic.onValueReceived.listen((value) {
              //print("📡 Live data received: $value");

              // Si données binaires → convertir en string
              /*final decoded = String.fromCharCodes(value);
              print("Decoded: $decoded");
              final json = jsonDecode(decoded);

              final sample = ShoeSample(
                steps: json["pas"],
                angleX: json["angle_x"],
                angleY: json["angle_y"],
                badPosition: json["mauvais_positionnement"],
                timestamp: DateTime.now(),
              );

              _shoeDataService.addSample(sample);*/
              startRandomSimulation();
            });
          }
        }
      }
    } catch (e) {
      print("Connection error: $e");
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  void startRandomSimulation() {
    print("--- Starting Random Sensor Simulation ---");

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _steps += _random.nextInt(2);

      final sample = ShoeSample(
        steps: _steps,
        angleX: 150 + _random.nextDouble() * 20,
        angleY: 140 + _random.nextDouble() * 20,
        badPosition: _random.nextBool(),
        timestamp: DateTime.now(),
      );

      _shoeDataService.addSample(sample);
    });
  }
}
