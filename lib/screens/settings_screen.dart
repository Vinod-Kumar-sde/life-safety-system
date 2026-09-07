import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool locationEnabled = true;
  bool fallDetectionEnabled = true;
  bool healthMonitoringEnabled = true;
  bool simulationMode = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      locationEnabled =
          prefs.getBool('location_enabled') ?? true;

      fallDetectionEnabled =
          prefs.getBool('fall_detection_enabled') ?? true;

      healthMonitoringEnabled =
          prefs.getBool('health_monitoring_enabled') ?? true;

      simulationMode =
          prefs.getBool('simulation_mode') ?? false;
    });
  }

  Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Safety Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              title: const Text('Location'),
              subtitle: const Text(
                'Allow the app to use your current location',
              ),
              secondary: const Icon(Icons.location_on),
              value: locationEnabled,
              onChanged: (value) {
                setState(() {
                  locationEnabled = value;
                });

                saveSetting('location_enabled', value);
              },
            ),
          ),

          Card(
            child: SwitchListTile(
              title: const Text('Fall Detection'),
              subtitle: const Text(
                'Monitor the wearable for possible falls',
              ),
              secondary: const Icon(
                Icons.accessibility_new,
              ),
              value: fallDetectionEnabled,
              onChanged: (value) {
                setState(() {
                  fallDetectionEnabled = value;
                });

                saveSetting(
                  'fall_detection_enabled',
                  value,
                );
              },
            ),
          ),

          Card(
            child: SwitchListTile(
              title: const Text('Health Monitoring'),
              subtitle: const Text(
                'Monitor heart rate and SpO₂',
              ),
              secondary: const Icon(Icons.favorite),
              value: healthMonitoringEnabled,
              onChanged: (value) {
                setState(() {
                  healthMonitoringEnabled = value;
                });

                saveSetting(
                  'health_monitoring_enabled',
                  value,
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Testing',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              title: const Text('Simulation Mode'),
              subtitle: const Text(
                'Use simulated wearable data without hardware',
              ),
              secondary: const Icon(Icons.science),
              value: simulationMode,
              onChanged: (value) {
                setState(() {
                  simulationMode = value;
                });

                saveSetting(
                  'simulation_mode',
                  value,
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Emergency System',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(Icons.contacts),
              title: const Text('Emergency Contacts'),
              subtitle: const Text(
                'Manage people who receive SOS alerts',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
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

          const SizedBox(height: 25),

          const Text(
            'About',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Card(
            child: ListTile(
              leading: Icon(Icons.shield),
              title: Text('Life Safety System'),
              subtitle: Text(
                'Emergency safety and health monitoring system\n'
                'Version 1.0.0',
              ),
            ),
          ),
        ],
      ),
    );
  }
}