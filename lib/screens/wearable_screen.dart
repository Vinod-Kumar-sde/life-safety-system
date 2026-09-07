import 'dart:async';

import 'package:flutter/material.dart';

import '../services/wearable_service.dart';

class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});

  @override
  State<WearableScreen> createState() =>
      _WearableScreenState();
}

class _WearableScreenState
    extends State<WearableScreen> {
  final WearableService wearable =
      WearableService.instance;

  bool scanning = false;

  final List<Map<String, dynamic>> devices = [
    {
      'name': 'Life Safety Band',
      'id': 'LSS-001',
      'signal': 'Strong',
    },
    {
      'name': 'Life Safety Band',
      'id': 'LSS-002',
      'signal': 'Medium',
    },
    {
      'name': 'Safety Wearable',
      'id': 'SW-101',
      'signal': 'Weak',
    },
  ];

  Timer? scanTimer;

  @override
  void dispose() {
    scanTimer?.cancel();
    super.dispose();
  }

  void startScan() {
    if (!wearable.simulationMode) {
      showMessage(
        'Simulation Mode is OFF. '
        'Simulated BLE scanning is disabled.',
      );
      return;
    }

    if (scanning) return;

    setState(() {
      scanning = true;
      devices.clear();
    });

    scanTimer = Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        if (!wearable.simulationMode) {
          setState(() {
            scanning = false;
          });
          return;
        }

        setState(() {
          devices.addAll([
            {
              'name': 'Life Safety Band',
              'id': 'LSS-001',
              'signal': 'Strong',
            },
            {
              'name': 'Safety Wearable',
              'id': 'SW-101',
              'signal': 'Medium',
            },
          ]);

          scanning = false;
        });
      },
    );
  }

  void connectDevice(
    Map<String, dynamic> device,
  ) {
    if (!wearable.simulationMode) {
      showMessage(
        'Simulation Mode is OFF.',
      );
      return;
    }

    wearable.connectSimulation();

    showMessage(
      '${device['name']} connected successfully.',
    );
  }

  void disconnectDevice() {
    wearable.disconnectSimulation();

    showMessage(
      'Wearable disconnected.',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: wearable,
      builder: (context, child) {
        final simulationEnabled =
            wearable.simulationMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Wearable'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              if (simulationEnabled) {
                startScan();

                await Future.delayed(
                  const Duration(seconds: 2),
                );
              }
            },
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(
                        wearable.connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 40,
                        color: wearable.connected
                            ? Colors.green
                            : Colors.grey,
                      ),
                      title: Text(
                        wearable.connected
                            ? 'Wearable Connected'
                            : 'Wearable Disconnected',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        wearable.connected
                            ? 'Life Safety wearable is active'
                            : simulationEnabled
                                ? 'Scan for simulated wearable devices'
                                : 'Simulation Mode is OFF',
                      ),
                      trailing: wearable.connected
                          ? IconButton(
                              icon: const Icon(
                                Icons.link_off,
                              ),
                              onPressed:
                                  disconnectDevice,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 55,
                            color: simulationEnabled
                                ? null
                                : Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'BLE Wearable Scanner',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            simulationEnabled
                                ? 'Search for nearby simulated Life Safety wearable devices.'
                                : 'Simulation Mode is OFF. Simulated scanning is disabled.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed:
                                  simulationEnabled &&
                                          !scanning
                                      ? startScan
                                      : null,
                              icon: scanning
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search,
                                    ),
                              label: Text(
                                scanning
                                    ? 'Scanning...'
                                    : 'Scan for Wearables',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      scanning
                          ? 'Searching for devices...'
                          : 'Nearby Devices',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (scanning)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text(
                            'Scanning for BLE devices...',
                          ),
                        ],
                      ),
                    ),

                  if (!scanning &&
                      devices.isEmpty &&
                      simulationEnabled)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 50,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No wearable devices found.',
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (!simulationEnabled)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 50,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Simulation Mode is OFF.',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Simulated wearable devices are unavailable.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (simulationEnabled)
                    ...devices.map(
                      (device) {
                        final isConnected =
                            wearable.connected &&
                                device['id'] ==
                                    'LSS-001';

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.watch,
                              size: 38,
                              color: isConnected
                                  ? Colors.green
                                  : null,
                            ),
                            title: Text(
                              device['name'],
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'ID: ${device['id']}\n'
                              'Signal: ${device['signal']}',
                            ),
                            isThreeLine: true,
                            trailing:
                                ElevatedButton(
                              onPressed: isConnected
                                  ? null
                                  : () {
                                      connectDevice(
                                        device,
                                      );
                                    },
                              child: Text(
                                isConnected
                                    ? 'Connected'
                                    : 'Connect',
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 15),

                  Card(
                    color: simulationEnabled
                        ? Colors.blue.shade50
                        : Colors.grey.shade200,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: simulationEnabled
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              simulationEnabled
                                  ? 'Simulation Mode is ON. Wearable scanning and sensor data are simulated.'
                                  : 'Simulation Mode is OFF. No simulated wearable data will be generated.',
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
        );
      },
    );
  }
}