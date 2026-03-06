import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modar/providers.dart';
import 'package:modar/services/bluetooth_service.dart';

class DebugConsoleScreen extends ConsumerStatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  ConsumerState<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends ConsumerState<DebugConsoleScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final List<BleLogEntry> _logs = [];
  StreamSubscription<BleLogEntry>? _sub;
  bool _autoScroll = true;
  bool _paused = false;
  bool _isSimulating = false;
  String _filter = '';

  static const _tagColors = <String, Color>{
    'SCAN': Color(0xFF2196F3),
    'PERM': Color(0xFF9C27B0),
    'CONN': Color(0xFF4CAF50),
    'SVC': Color(0xFF00BCD4),
    'CHR': Color(0xFF009688),
    'RAW': Color(0xFF757575),
    'JSON': Color(0xFFFF9800),
    'BIN': Color(0xFFFF9800),
    'DATA': Color(0xFF8BC34A),
    'SIM': Color(0xFFFFEB3B),
    'ERR': Color(0xFFF44336),
    '???': Color(0xFFE91E63),
  };

  @override
  void initState() {
    super.initState();
    final btService = ref.read(bluetoothServiceProvider);
    _isSimulating = btService.isSimulating;
    // Load existing logs
    _logs.addAll(btService.logs);
    // Listen for new logs
    _sub = btService.logStream.listen((entry) {
      if (_paused) return;
      setState(() => _logs.add(entry));
      if (_autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggleSimulation() {
    final btService = ref.read(bluetoothServiceProvider);
    if (btService.isSimulating) {
      btService.stopSimulation();
    } else {
      btService.startRandomSimulation();
    }
    setState(() => _isSimulating = btService.isSimulating);
  }

  List<BleLogEntry> get _filteredLogs {
    if (_filter.isEmpty) return _logs;
    final f = _filter.toUpperCase();
    return _logs.where((e) =>
        e.tag.contains(f) || e.message.toUpperCase().contains(f)).toList();
  }

  void _copyAll() {
    final text = _filteredLogs
        .map((e) => '[${_ts(e.time)}] [${e.tag}] ${e.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _ts(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}.'
      '${t.millisecond.toString().padLeft(3, '0')}';

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            const Text('BLE Console',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: Colors.white)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white70),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause,
                color: _paused ? Colors.orange : Colors.white70),
            tooltip: _paused ? 'Resume' : 'Pause',
            onPressed: () => setState(() => _paused = !_paused),
          ),
          IconButton(
            icon: Icon(Icons.vertical_align_bottom,
                color: _autoScroll ? Colors.greenAccent : Colors.white38),
            tooltip: 'Auto-scroll',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
            tooltip: 'Copy all',
            onPressed: _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Clear',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleSimulation,
        icon: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
        label: Text(_isSimulating ? 'Stop' : 'Simuler'),
        backgroundColor: _isSimulating ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: const Color(0xFF252526),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Filter (tag or text)...',
                hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.filter_list,
                    color: Colors.white38, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          // Chip filters
          Container(
            color: const Color(0xFF252526),
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _tagColors.entries.map((e) {
                final selected = _filter.toUpperCase() == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() =>
                        _filter = selected ? '' : e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? e.value.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: selected
                            ? Border.all(color: e.value, width: 1)
                            : null,
                      ),
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: selected ? e.value : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3C3C3C)),
          // Log list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _logs.isEmpty
                          ? 'No logs yet.\nConnect a BLE device or start simulation.'
                          : 'No logs matching "$_filter"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: filtered.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (_, i) {
                      final log = filtered[i];
                      final tagColor =
                          _tagColors[log.tag] ?? Colors.white54;
                      return InkWell(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  '[${_ts(log.time)}] [${log.tag}] ${log.message}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Line copied'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(milliseconds: 600),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timestamp
                              Text(
                                _ts(log.time),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color:
                                      Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Tag
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  log.tag,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tagColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Message
                              Expanded(
                                child: Text(
                                  log.message,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: log.tag == 'ERR'
                                        ? const Color(0xFFF44336)
                                        : Colors.white.withValues(
                                            alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
