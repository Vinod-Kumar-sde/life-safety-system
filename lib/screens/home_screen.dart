import 'package:flutter/material.dart';

import 'mode_selection_screen.dart';
import 'settings_screen.dart';
import 'contacts_screen.dart';
import 'location_screen.dart';
import 'sos_screen.dart';

import '../services/network_service.dart';
import '../services/wearable_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool internetConnected = false;

  @override
  void initState() {
    super.initState();
    checkInternet();
  }

  Future<void> checkInternet() async {
    final connected = await NetworkService.isConnected();

    if (!mounted) return;

    setState(() {
      internetConnected = connected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WearableService.instance,
      builder: (context, child) {
        final wearable = WearableService.instance;
        final connected = wearable.connected;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Life Safety System'),
            actions: [
              IconButton(
                icon: const Icon(Icons.contacts),
                tooltip: 'Emergency Contacts',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ContactsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SettingsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Switch Safety Mode',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ModeSelectionScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          body: RefreshIndicator(
            onRefresh: () async {
              await checkInternet();
              wearable.generateTestData();

              await Future.delayed(
                const Duration(milliseconds: 500),
              );
            },

            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  // Welcome
                  Card(
                    elevation: 3,
                    color: Colors.red.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.shield,
                            size: 60,
                            color: Colors.red,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Life Safety System',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your personal safety and health monitoring system',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Internet status
                  Card(
                    child: ListTile(
                      leading: Icon(
                        internetConnected
                            ? Icons.wifi
                            : Icons.wifi_off,
                        color: internetConnected
                            ? Colors.green
                            : Colors.red,
                        size: 35,
                      ),
                      title: const Text(
                        'Internet Connection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        internetConnected
                            ? 'Internet is available'
                            : 'Internet unavailable - GSM backup may be required',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Wearable status
                  Card(
                    child: ListTile(
                      leading: Icon(
                        connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: connected
                            ? Colors.green
                            : Colors.grey,
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
                            ? 'Wearable connected'
                            : 'Wearable disconnected',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Health data
                  Row(
                    children: [
                      Expanded(
                        child: _dataCard(
                          Icons.favorite,
                          'Heart Rate',
                          connected
                              ? '${wearable.heartRate} BPM'
                              : '-- BPM',
                        ),
                      ),
                      Expanded(
                        child: _dataCard(
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

                  // Fall detection
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
                            ? 'Unavailable'
                            : wearable.fallDetected
                                ? 'Possible fall detected!'
                                : 'No fall detected',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Battery
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

                  // SOS
                  SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SOSScreen(),
                          ),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 40,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'SEND SOS',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Location
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 35,
                      ),
                      title: const Text(
                        'Live Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'View your current GPS location',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LocationScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Contacts
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.contacts,
                        color: Colors.orange,
                        size: 35,
                      ),
                      title: const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Manage trusted emergency contacts',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ContactsScreen(),
                          ),
                        );
                      },
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

  Widget _dataCard(
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
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}