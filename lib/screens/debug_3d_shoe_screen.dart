import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/models/ShoeSample.dart';
import 'package:modar/providers.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Chunk size for sending large base64 strings to WebView
const int _kChunkSize = 50000;

class Debug3dShoeScreen extends ConsumerStatefulWidget {
  const Debug3dShoeScreen({super.key});

  @override
  ConsumerState<Debug3dShoeScreen> createState() => _Debug3dShoeScreenState();
}

class _Debug3dShoeScreenState extends ConsumerState<Debug3dShoeScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _simulating = false;
  StreamSubscription<ShoeSample>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F5F5));
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('assets/3dshoe.html');
    final glbBytes = await rootBundle.load('assets/3dshoe.glb');
    final glbBase64 = base64Encode(glbBytes.buffer.asUint8List());

    await _controller.loadHtmlString(html);

    // Wait for page to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Send GLB data in chunks to avoid JavaScript string length limits
    if (glbBase64.length > _kChunkSize) {
      await _controller.runJavaScript('window._glbChunks = [];');
      for (int i = 0; i < glbBase64.length; i += _kChunkSize) {
        final end = (i + _kChunkSize).clamp(0, glbBase64.length);
        final chunk = glbBase64.substring(i, end);
        await _controller.runJavaScript("window._glbChunks.push('$chunk');");
      }
      await _controller.runJavaScript('loadGLB(window._glbChunks.join(""));');
    } else {
      await _controller.runJavaScript("loadGLB('$glbBase64');");
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _simulating = ref.read(bluetoothServiceProvider).isSimulating;
    });
    _listenToBle();
  }

  void _listenToBle() {
    final shoeDataService = ref.read(shoeDataServiceProvider);
    _subscription = shoeDataService.stream.listen(_onSample);
  }

  void _onSample(ShoeSample sample) {
    final json = jsonEncode({
      'pas': sample.steps,
      'distance_m': sample.distanceM?.toStringAsFixed(2) ?? (sample.steps * 0.70).toStringAsFixed(2),
      'angle_x': sample.angleX,
      'angle_y': sample.angleY,
      'ax': sample.ax ?? 0.0,
      'ay': sample.ay ?? 0.0,
      'az': sample.az ?? 0.0,
      'gx': sample.gx ?? 0.0,
      'gy': sample.gy ?? 0.0,
      'gz': sample.gz ?? 0.0,
      'mag': sample.mag ?? 1.0,
      'delta': sample.delta ?? 0.0,
      'mauvais_positionnement': sample.badPosition,
      'poids_talon_g': sample.poidsTalon ?? 0.0,
      'poids_avantpied_g': sample.poidsAvantpied ?? 0.0,
    });
    _controller.runJavaScript("updateShoe('${json.replaceAll("'", "\\'")}')");
  }

  void _calibrate() {
    _controller.runJavaScript('calibrate()');
  }

  void _toggleSimulation() {
    final btService = ref.read(bluetoothServiceProvider);
    if (btService.isSimulating) {
      btService.stopSimulation();
    } else {
      btService.startRandomSimulation();
    }
    setState(() => _simulating = btService.isSimulating);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    if (_simulating) {
      ref.read(bluetoothServiceProvider).stopSimulation();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btService = ref.read(bluetoothServiceProvider);
    final connected = btService.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug 3D Shoe'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _simulating
                        ? Colors.orange
                        : connected
                            ? Colors.green
                            : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _simulating
                      ? 'Simulation'
                      : connected
                          ? 'BLE connecté'
                          : 'Déconnecté',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _controller),
      floatingActionButton: _loading
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'calibrate',
                  onPressed: _calibrate,
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.gps_fixed, size: 20),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'simulate',
                  onPressed: _toggleSimulation,
                  icon: Icon(_simulating ? Icons.stop : Icons.play_arrow),
                  label: Text(_simulating ? 'Stop' : 'Simuler'),
                  backgroundColor: _simulating ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
    );
  }
}
