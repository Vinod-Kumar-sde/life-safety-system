import 'package:flutter/material.dart';

import '../services/wearable_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final connected = WearableService.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitoring'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  size: 35,
                ),
                title: const Text('Wearable Status'),
                subtitle: Text(
                  connected
                      ? 'Connected'
                      : 'Disconnected - no sensor data',
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _healthCard(
                    Icons.favorite,
                    'Heart Rate',
                    connected
                        ? '${WearableService.heartRate} BPM'
                        : '-- BPM',
                  ),
                ),
                Expanded(
                  child: _healthCard(
                    Icons.bloodtype,
                    'SpO₂',
                    connected
                        ? '${WearableService.spo2}%'
                        : '-- %',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Icon(
                  WearableService.fallDetected
                      ? Icons.warning
                      : Icons.check_circle,
                  size: 35,
                ),
                title: const Text('Fall Detection'),
                subtitle: Text(
                  !connected
                      ? 'Unavailable - wearable disconnected'
                      : WearableService.fallDetected
                          ? 'Possible fall detected!'
                          : 'No fall detected',
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.battery_full,
                  size: 35,
                ),
                title: const Text('Wearable Battery'),
                subtitle: Text(
                  connected
                      ? '${WearableService.battery}% remaining'
                      : 'Unavailable',
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  connected
                      ? 'Health data is being received from the wearable.'
                      : 'Connect the wearable to view real-time '
                        'heart rate, SpO₂ and fall detection data.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 35,
            ),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}