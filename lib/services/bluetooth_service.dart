import 'dart:async';
import 'dart:developer' as dev;
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
    dev.log('Starting scan sequence', name: 'BLE');

    if (Platform.isAndroid) {
      final statuses =
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

      statuses.forEach((p, s) => dev.log('$p -> $s', name: 'BLE.permissions'));

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
    dev.log('Connecting to ${device.remoteId}', name: 'BLE');

    try {
      await device.connect(license: License.free, autoConnect: false);

      dev.log('Connected successfully', name: 'BLE');

      // 🔥 Découverte des services
      final List<BluetoothService> services = await device.discoverServices();

      for (final BluetoothService service in services) {
        dev.log('Service found: ${service.uuid}', name: 'BLE');

        for (final BluetoothCharacteristic characteristic
            in service.characteristics) {
          dev.log('Characteristic: ${characteristic.uuid}', name: 'BLE');

          // Si la caractéristique supporte notifications
          if (characteristic.properties.notify) {
            dev.log(
              'Enabling notifications on ${characteristic.uuid}',
              name: 'BLE',
            );
            await characteristic.setNotifyValue(true);

            characteristic.onValueReceived.listen((value) {
              dev.log('Live data received: $value', name: 'BLE.data');
              final decoded = String.fromCharCodes(value);
              dev.log('Decoded: $decoded', name: 'BLE.data');
            });
          }
        }
      }
    } catch (e) {
      dev.log('Connection error: $e', name: 'BLE', error: e);
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }
}
