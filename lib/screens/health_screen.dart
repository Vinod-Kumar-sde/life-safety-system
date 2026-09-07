import 'package:flutter/material.dart';

import '../services/wearable_service.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WearableService.instance,
      builder: (context, child) {
        final wearable = WearableService.instance;
        final connected = wearable.connected;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Health Monitoring'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              wearable.generateTestData();

              await Future.delayed(
                const Duration(milliseconds: 500),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      title: const Text(
                        'Wearable Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                              ? '${wearable.heartRate} BPM'
                              : '-- BPM',
                        ),
                      ),
                      Expanded(
                        child: _healthCard(
                          Icons.bloodtype,
                          'SpO₂',
                          connected
                              ? '${wearable.spo2}%'
                              : '-- %',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: ListTile(
                      leading: Icon(
                        wearable.fallDetected
                            ? Icons.warning
                            : Icons.check_circle,
                        color: wearable.fallDetected
                            ? Colors.red
                            : Colors.green,
                        size: 35,
                      ),
                      title: const Text(
                        'Fall Detection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        !connected
                            ? 'Unavailable - wearable disconnected'
                            : wearable.fallDetected
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
                      title: const Text(
                        'Wearable Battery',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        connected
                            ? '${wearable.battery}% remaining'
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
                            : 'Connect the wearable to view real-time heart rate, SpO₂ and fall detection data.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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