import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/models/session.dart';
import 'package:modar/services/ShoeDataService.dart';
import 'package:modar/services/bluetooth_service.dart';
import 'package:modar/services/database_service.dart';
import 'package:modar/state/shoe_session_state.dart';
import 'package:modar/viewModel/shoe_session_viewmodel.dart';

final shoeDataServiceProvider = Provider<ShoeDataService>((ref) {
  return ShoeDataService();
});

final bluetoothServiceProvider = Provider<AppBluetoothService>((ref) {
  final shoeService = ref.watch(shoeDataServiceProvider);
  return AppBluetoothService(shoeService);
});

final shoeSessionViewModelProvider =
    StateNotifierProvider<ShoeSessionViewModel, ShoeSessionState>((ref) {
      final shoeService = ref.watch(shoeDataServiceProvider);
      return ShoeSessionViewModel(shoeService);
    });

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final sessionsProvider = FutureProvider<List<Session>>((ref) {
  return ref.read(databaseServiceProvider).getSessions();
});
