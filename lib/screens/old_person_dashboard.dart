import 'package:flutter/material.dart';

import 'mode_selection_screen.dart';
import 'settings_screen.dart';
import 'sos_screen.dart';
import 'location_screen.dart';
import 'contacts_screen.dart';
import 'wearable_screen.dart';

import '../services/wearable_service.dart';

class OldPersonDashboard extends StatefulWidget {
  const OldPersonDashboard({super.key});

  @override
  State<OldPersonDashboard> createState() =>
      _OldPersonDashboardState();
}

class _OldPersonDashboardState
    extends State<OldPersonDashboard> {
  final WearableService wearable = WearableService.instance;

  bool fallDialogShowing = false;
  bool previousFallState = false;

  @override
  void initState() {
    super.initState();

    previousFallState = wearable.fallDetected;
    wearable.addListener(checkFallDetection);
  }

  @override
  void dispose() {
    wearable.removeListener(checkFallDetection);
    super.dispose();
  }

  void checkFallDetection() {
    if (!mounted) return;

    // Show alert only when fall changes from false -> true.
    if (wearable.fallDetected &&
        !previousFallState &&
        !fallDialogShowing) {
      previousFallState = true;
      showFallAlert();
    }

    if (!wearable.fallDetected) {
      previousFallState = false;
    }
  }

  void showFallAlert() {
    if (!mounted) return;

    fallDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Fall Detected'),
              ),
            ],
          ),
          content: const Text(
            'The wearable detected a possible fall.\n\n'
            'Are you safe? If you need help, send an SOS alert to your emergency contacts.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                wearable.clearFallAlert();

                fallDialogShowing = false;
              },
              child: const Text('I AM SAFE'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);

                fallDialogShowing = false;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SOSScreen(),
                  ),
                );
              },
              child: const Text('SEND SOS'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: wearable,
      builder: (context, child) {
        final connected = wearable.connected;
        final fallDetected = wearable.fallDetected;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ModeSelectionScreen(),
              ),
            );
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Old Person',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Health Dashboard',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
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
                    // Welcome card
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Monitoring',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Monitor vital signs and receive emergency assistance instantly.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Wearable
                    Card(
                      child: ListTile(
                        leading: Icon(
                          connected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: connected
                              ? Colors.green
                              : Colors.grey,
                          size: 38,
                        ),
                        title: const Text(
                          'Wearable',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          connected
                              ? 'Connected'
                              : 'Disconnected - health data unavailable',
                        ),
                        trailing: Icon(
                          connected
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: connected
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Heart rate + SpO2
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

                    // Fall detection
                    Card(
                      color: fallDetected
                          ? Colors.red.shade50
                          : null,
                      child: ListTile(
                        leading: Icon(
                          fallDetected
                              ? Icons.warning
                              : Icons.check_circle,
                          color: fallDetected
                              ? Colors.red
                              : Colors.green,
                          size: 38,
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
                              : fallDetected
                                  ? '⚠ Possible fall detected!'
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
                          size: 38,
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

                    const SizedBox(height: 18),

                    // Quick actions
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        _quickButton(
                          context,
                          Icons.favorite,
                          'Health',
                          Colors.red,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WearableScreen(),
                              ),
                            );
                          },
                        ),
                        _quickButton(
                          context,
                          Icons.location_on,
                          'Location',
                          Colors.green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LocationScreen(),
                              ),
                            );
                          },
                        ),
                        _quickButton(
                          context,
                          Icons.contacts,
                          'Caretaker',
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ContactsScreen(),
                              ),
                            );
                          },
                        ),
                        _quickButton(
                          context,
                          Icons.watch,
                          'Wearable',
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WearableScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // SOS
                    SizedBox(
                      width: double.infinity,
                      height: 115,
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
                              size: 42,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'SEND SOS ALERT',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Location
                    _optionCard(
                      context,
                      Icons.location_on,
                      'Location',
                      'View current location',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LocationScreen(),
                          ),
                        );
                      },
                    ),

                    // Caretaker
                    _optionCard(
                      context,
                      Icons.contacts,
                      'Caretaker / Emergency Contacts',
                      'Manage trusted contacts',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ContactsScreen(),
                          ),
                        );
                      },
                    ),

                    // Wearable
                    _optionCard(
                      context,
                      Icons.watch,
                      'Wearable Details',
                      'View wearable sensor information',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const WearableScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: Colors.blue,
                              size: 30,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'The wearable continuously provides health and fall detection information.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
              size: 38,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickButton(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(
          Icons.arrow_forward_ios,
          size: 0,
        ),
        title: Row(
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 17,
        ),
        onTap: onTap,
      ),
    );
  }
}