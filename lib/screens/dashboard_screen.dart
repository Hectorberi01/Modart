import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';
import 'bluetooth_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _saveSession(BuildContext context) async {
    final now = DateTime.now();
    final session = Session(
      title: 'Session ${DateFormat('HH:mm').format(now)}',
      date: DateFormat('dd MMMM yyyy').format(now),
      time: DateFormat('HH:mm').format(now),
      duration: '12:34', // Mocked for now
      distance: '2.4 km', // Mocked for now
      avgSpeed: '8.5 km/h', // Mocked for now
    );

    await DatabaseService().insertSession(session);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session enregistrée avec succès !'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BluetoothScreen(
                          onContinue: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bluetooth, size: 20, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('00:12:34', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _MetricCard(
              label: 'Distance parcourue',
              value: '2.4',
              unit: 'km',
            ),
            const SizedBox(height: 16),
            const _SpeedGaugeCard(
              label: 'Vitesse actuelle',
              value: '8.5',
              unit: 'km/h',
            ),
            const SizedBox(height: 16),
            const _WeightBalanceCard(
              totalWeight: '72.3',
              leftPercent: 0.52,
              rightPercent: 0.48,
            ),
            const SizedBox(height: 16),
            _MetricCard(
              label: 'Temps écoulé',
              value: '12:34',
              unit: 'minutes',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _saveSession(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F7),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Terminer la session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedGaugeCard extends StatelessWidget {
  const _SpeedGaugeCard({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 0.6,
                    strokeWidth: 12,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightBalanceCard extends StatelessWidget {
  const _WeightBalanceCard({
    required this.totalWeight,
    required this.leftPercent,
    required this.rightPercent,
  });
  final String totalWeight;
  final double leftPercent;
  final double rightPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Poids total', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalWeight, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('kg', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _BalanceBar(label: 'Pied gauche', percent: leftPercent),
          const SizedBox(height: 16),
          _BalanceBar(label: 'Pied droit', percent: rightPercent),
        ],
      ),
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.label, required this.percent});
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text('${(percent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.black.withOpacity(0.05),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black54),
          ),
        ),
      ],
    );
  }
}
