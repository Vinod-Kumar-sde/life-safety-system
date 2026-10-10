import 'dart:async';

import 'package:flutter/material.dart';

import '../services/wearable_service.dart';
import 'sos_screen.dart';

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
  bool fallOpeningSOS = false;

  final List<Map<String, dynamic>> simulatedDevices = [
    {
      'name': 'Life Safety Band LSS-001',
      'signal': 'Strong',
      'icon': Icons.watch,
    },
    {
      'name': 'Life Safety Band LSS-002',
      'signal': 'Medium',
      'icon': Icons.watch,
    },
    {
      'name': 'Safety Wearable SW-101',
      'signal': 'Weak',
      'icon': Icons.watch_outlined,
    },
  ];

  List<Map<String, dynamic>> discoveredDevices = [];

  bool previousFallState = false;

  @override
  void initState() {
    super.initState();

    previousFallState = wearable.fallDetected;

    wearable.addListener(checkFallDetection);

    wearable.loadSimulationMode();
  }

  @override
  void dispose() {
    wearable.removeListener(checkFallDetection);
    super.dispose();
  }

  void checkFallDetection() {
    if (!mounted) {
      return;
    }

    if (wearable.fallDetected &&
        !previousFallState &&
        !fallOpeningSOS) {
      previousFallState = true;
      openAutomaticSOS();
    }

    if (!wearable.fallDetected) {
      previousFallState = false;
    }
  }

  void openAutomaticSOS() {
    if (!mounted || fallOpeningSOS) {
      return;
    }

    fallOpeningSOS = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SOSScreen(
          autoSend: true,
        ),
      ),
    ).then((_) {
      if (mounted) {
        fallOpeningSOS = false;
      }
    });
  }

  Future<void> startScan() async {
    if (!wearable.simulationMode ||
        wearable.connected) {
      return;
    }

    setState(() {
      scanning = true;
      discoveredDevices = [];
    });

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      discoveredDevices =
          List<Map<String, dynamic>>.from(
        simulatedDevices,
      );

      scanning = false;
    });
  }

  void connectDevice(
    Map<String, dynamic> device,
  ) {
    if (!wearable.simulationMode) {
      return;
    }

    wearable.connectSimulation();
  }

  void disconnectDevice() {
    wearable.disconnectSimulation();
  }

  void testFall() {
    if (!canTest()) {
      return;
    }

    wearable.simulateFall();
  }

  void testHighHeartRate() {
    if (!canTest()) {
      return;
    }

    wearable.updateSensorData(
      newHeartRate: 130,
    );
  }

  void testLowHeartRate() {
    if (!canTest()) {
      return;
    }

    wearable.updateSensorData(
      newHeartRate: 45,
    );
  }

  void testLowSpo2() {
    if (!canTest()) {
      return;
    }

    wearable.updateSensorData(
      newSpo2: 90,
    );
  }

  void testLowBattery() {
    if (!canTest()) {
      return;
    }

    wearable.updateSensorData(
      newBattery: 10,
    );
  }

  void restoreNormalData() {
    if (!canTest()) {
      return;
    }

    wearable.updateSensorData(
      newHeartRate: 72,
      newSpo2: 98,
      newBattery: 100,
      newFallDetected: false,
    );

    wearable.clearFallAlert();
  }

  bool canTest() {
    return wearable.simulationMode &&
        wearable.connected;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: wearable,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Wearable',
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              if (wearable.simulationMode &&
                  wearable.connected) {
                wearable.generateTestData();
              }

              await Future.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStatusCard(),

                  const SizedBox(height: 20),

                  _buildScannerCard(),

                  const SizedBox(height: 20),

                  _buildNearbyDevices(),

                  if (wearable.simulationMode) ...[
                    const SizedBox(height: 20),
                    _buildSimulationTests(),
                  ],

                  const SizedBox(height: 20),

                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    final connected =
        wearable.connected;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              connected
                  ? Icons.watch
                  : Icons.watch_outlined,
              size: 60,
              color: connected
                  ? Colors.green
                  : Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              connected
                  ? 'Wearable Connected'
                  : 'Wearable Not Connected',
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              wearable.simulationMode
                  ? 'Simulation Mode'
                  : 'Hardware Mode',
              style: TextStyle(
                color:
                    wearable.simulationMode
                        ? Colors.orange
                        : Colors.blue,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            if (connected) ...[
              const SizedBox(height: 18),

              const Divider(),

              const SizedBox(height: 10),

              _dataRow(
                Icons.favorite,
                'Heart Rate',
                '${wearable.heartRate} BPM',
              ),

              _dataRow(
                Icons.bloodtype,
                'SpO₂',
                '${wearable.spo2}%',
              ),

              _dataRow(
                Icons.battery_std,
                'Battery',
                '${wearable.battery}%',
              ),

              _dataRow(
                wearable.fallDetected
                    ? Icons.warning
                    : Icons.check_circle,
                'Fall Detection',
                wearable.fallDetected
                    ? 'Detected'
                    : 'Normal',
              ),

              if (wearable.fallDetected) ...[
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⚠ Fall detected. SOS countdown has been started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      disconnectDevice,
                  icon: const Icon(
                    Icons.link_off,
                  ),
                  label: const Text(
                    'Disconnect',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dataRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.grey.shade700,
          ),

          const SizedBox(width: 10),

          Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    final disabled =
        !wearable.simulationMode ||
            wearable.connected;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bluetooth,
                  color: Colors.blue,
                ),
                SizedBox(width: 10),
                Text(
                  'Bluetooth Scanner',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              wearable.simulationMode
                  ? 'Search for nearby simulated safety wearables.'
                  : 'Simulation scanning is disabled.',
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    disabled || scanning
                        ? null
                        : startScan,
                icon: scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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
    );
  }

  Widget _buildNearbyDevices() {
    if (discoveredDevices.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        child: const Padding(
          padding:
              EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 45,
                color: Colors.grey,
              ),

              SizedBox(height: 10),

              Text(
                'No devices discovered',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Tap Scan for Wearables to search.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Padding(
              padding:
                  EdgeInsets.all(4),
              child: Text(
                'Nearby Devices',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            ...discoveredDevices.map(
              (device) {
                return ListTile(
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 4,
                  ),
                  leading:
                      CircleAvatar(
                    child: Icon(
                      device['icon']
                          as IconData,
                    ),
                  ),
                  title: Text(
                    device['name']
                        as String,
                  ),
                  subtitle: Text(
                    'Signal: ${device['signal']}',
                  ),
                  trailing:
                      ElevatedButton(
                    onPressed:
                        wearable.connected
                            ? null
                            : () {
                                connectDevice(
                                  device,
                                );
                              },
                    child: Text(
                      wearable.connected
                          ? 'Connected'
                          : 'Connect',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationTests() {
    final enabled =
        wearable.connected;

    return Card(
      elevation: 0,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.orange.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.science,
                  color: Colors.orange,
                ),
                SizedBox(width: 10),
                Text(
                  'Safety Test Controls',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const Text(
              'Simulation-only controls for demonstrating each safety alert.',
              style:
                  TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            _testButton(
              label:
                  'Test Fall Detection',
              icon:
                  Icons.warning_rounded,
              enabled: enabled,
              onPressed: testFall,
            ),

            _testButton(
              label:
                  'Test High Heart Rate',
              icon: Icons.favorite,
              enabled: enabled,
              onPressed:
                  testHighHeartRate,
            ),

            _testButton(
              label:
                  'Test Low Heart Rate',
              icon:
                  Icons.favorite_border,
              enabled: enabled,
              onPressed:
                  testLowHeartRate,
            ),

            _testButton(
              label: 'Test Low SpO₂',
              icon: Icons.bloodtype,
              enabled: enabled,
              onPressed: testLowSpo2,
            ),

            _testButton(
              label:
                  'Test Low Battery',
              icon:
                  Icons.battery_alert,
              enabled: enabled,
              onPressed:
                  testLowBattery,
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    enabled
                        ? restoreNormalData
                        : null,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Restore Normal Values',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        child:
            OutlinedButton.icon(
          onPressed:
              enabled
                  ? onPressed
                  : null,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Colors.blue.withOpacity(
          0.06,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.blue.withOpacity(
            0.12,
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                'Wearable Safety System',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Text(
            'The wearable monitors health and safety conditions and sends alerts to the Safety Notification Center when abnormal conditions are detected.',
            style:
                TextStyle(
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}