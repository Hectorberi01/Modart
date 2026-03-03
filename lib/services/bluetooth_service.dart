import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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

    // ⚠️ iOS : ne demande PAS Permission.bluetooth ici

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

  Future<void> connect(BluetoothDevice device) async {
    print("--- AppBluetoothService: Connecting to ${device.remoteId} ---");
    try {
      await device.connect(license: License.free, autoConnect: false);
      print("--- AppBluetoothService: Successfully connected ---");
    } catch (e) {
      print("--- AppBluetoothService: Connection error: $e ---");
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }
}
