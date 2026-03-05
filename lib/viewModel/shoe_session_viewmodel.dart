import 'dart:async';
import 'package:modar/services/ShoeDataService.dart';
import 'package:modar/state/shoe_session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ShoeSample.dart';

class ShoeSessionViewModel extends StateNotifier<ShoeSessionState> {
  final ShoeDataService _service;

  StreamSubscription? _subscription;

  ShoeSessionViewModel(this._service) : super(const ShoeSessionState()) {
    _listenStream();
  }

  void _listenStream() {
    _subscription = _service.stream.listen((ShoeSample sample) {
      final steps = _service.computeTotalSteps();
      final distance = _service.estimateDistanceMeters();
      final cadence = _service.estimateCadence();
      final posture = _service.computePostureScore();
      final globalScore = _service.computeGlobalScore();

      state = state.copyWith(
        steps: steps,
        distance: distance,
        cadence: cadence,
        postureScore: posture,
        globalScore: globalScore,
        badPosition: sample.badPosition,
        poidsTalon: sample.poidsTalon ?? 0,
        poidsAvantpied: sample.poidsAvantpied ?? 0,
      );
    });
  }

  void resetSession() {
    _service.resetSession();
    state = const ShoeSessionState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
