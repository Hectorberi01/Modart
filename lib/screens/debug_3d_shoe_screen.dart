import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/models/ShoeSample.dart';
import 'package:modar/providers.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    await _controller.loadHtmlString(html);
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
      'gx': sample.gx ?? 0.0,
      'gy': sample.gy ?? 0.0,
      'gz': sample.gz ?? 0.0,
      'mag': sample.mag ?? 1.0,
      'delta': sample.delta ?? 0.0,
      'mauvais_positionnement': sample.badPosition,
    });
    _controller.runJavaScript("updateShoe('${json.replaceAll("'", "\\'")}')");
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
          : FloatingActionButton.extended(
              onPressed: _toggleSimulation,
              icon: Icon(_simulating ? Icons.stop : Icons.play_arrow),
              label: Text(_simulating ? 'Stop' : 'Simuler'),
              backgroundColor: _simulating ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
    );
  }
}
