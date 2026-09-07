import 'package:flutter/material.dart';

import 'contacts_screen.dart';
import 'sos_screen.dart';
import 'location_screen.dart';
import 'settings_screen.dart';
import '../services/network_service.dart';
import '../services/wearable_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool networkConnected = true;

  @override
  void initState() {
    super.initState();
    checkNetwork();
  }

  Future<void> checkNetwork() async {
    final connected = await NetworkService.isConnected();

    if (!mounted) return;

    setState(() {
      networkConnected = connected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wearableConnected = WearableService.connected;
    final fallDetected = WearableService.fallDetected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Safety System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Internet status
            Card(
              child: ListTile(
                leading: Icon(
                  networkConnected
                      ? Icons.wifi
                      : Icons.wifi_off,
                  size: 35,
                ),
                title: const Text('Internet'),
                subtitle: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: networkConnected
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      networkConnected
                          ? 'Connected'
                          : 'No internet connection',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Wearable status
            Card(
              child: ListTile(
                leading: Icon(
                  wearableConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  size: 35,
                ),
                title: const Text('Wearable'),
                subtitle: Text(
                  wearableConnected
                      ? 'Connected'
                      : 'Not connected',
                ),
                trailing: Icon(
                  wearableConnected
                      ? Icons.check_circle
                      : Icons.bluetooth_disabled,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // SOS button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SOSScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 60,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Emergency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Health',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 35,
                          ),
                          const SizedBox(height: 8),
                          const Text('Heart Rate'),
                          const SizedBox(height: 5),
                          Text(
                            wearableConnected
                                ? '${WearableService.heartRate} BPM'
                                : '-- BPM',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.bloodtype,
                            size: 35,
                          ),
                          const SizedBox(height: 8),
                          const Text('SpO₂'),
                          const SizedBox(height: 5),
                          Text(
                            wearableConnected
                                ? '${WearableService.spo2}%'
                                : '-- %',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Fall detection
            Card(
              child: ListTile(
                leading: Icon(
                  fallDetected
                      ? Icons.warning
                      : Icons.check_circle,
                  size: 35,
                ),
                title: const Text('Fall Detection'),
                subtitle: Text(
                  !wearableConnected
                      ? 'Unavailable - wearable disconnected'
                      : fallDetected
                          ? 'Possible fall detected!'
                          : 'No fall detected',
                ),
                trailing: Icon(
                  fallDetected
                      ? Icons.warning
                      : Icons.check_circle,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Location
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  size: 35,
                ),
                title: const Text('Location'),
                subtitle: const Text(
                  'Tap to get your current location',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}