import 'package:flutter/material.dart';

import '../services/wearable_service.dart';

class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});

  @override
  State<WearableScreen> createState() => _WearableScreenState();
}

class _WearableScreenState extends State<WearableScreen> {
  void toggleConnection(bool value) {
    setState(() {
      if (value) {
        WearableService.connectSimulation();
      } else {
        WearableService.disconnectSimulation();
      }
    });
  }

  void generateData() {
    setState(() {
      WearableService.generateTestData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = WearableService.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearable'),
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
                  size: 40,
                ),
                title: Text(
                  connected
                      ? 'Wearable Connected'
                      : 'Wearable Disconnected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  connected
                      ? 'Simulation wearable is active'
                      : 'No wearable data available',
                ),
                trailing: Switch(
                  value: connected,
                  onChanged: toggleConnection,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (!connected)
              const Column(
                children: [
                  SizedBox(height: 40),
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Wearable Disconnected',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Connect the wearable to receive '
                    'health and safety data.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

            if (connected) ...[
              _dataCard(
                Icons.favorite,
                'Heart Rate',
                '${WearableService.heartRate} BPM',
              ),

              _dataCard(
                Icons.bloodtype,
                'SpO₂',
                '${WearableService.spo2}%',
              ),

              _batteryCard(),

              _fallCard(),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: generateData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate Test Data'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dataCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 38,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _batteryCard() {
    final battery = WearableService.battery;
    final lowBattery = battery <= 20;

    return Card(
      child: ListTile(
        leading: Icon(
          lowBattery
              ? Icons.battery_alert
              : Icons.battery_full,
          size: 38,
        ),
        title: const Text(
          'Wearable Battery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          lowBattery
              ? 'Low battery - please charge'
              : 'Battery level is normal',
        ),
        trailing: Text(
          '$battery%',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: lowBattery ? Colors.red : null,
          ),
        ),
      ),
    );
  }

  Widget _fallCard() {
    final fall = WearableService.fallDetected;

    return Card(
      child: ListTile(
        leading: Icon(
          fall
              ? Icons.warning
              : Icons.check_circle,
          size: 38,
        ),
        title: const Text(
          'Fall Detection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          fall
              ? 'Possible fall detected!'
              : 'No fall detected',
        ),
      ),
    );
  }
}