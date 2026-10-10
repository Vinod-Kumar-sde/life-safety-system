import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contacts_screen.dart';
import 'safety_notifications_screen.dart';
import '../services/wearable_service.dart';
import '../services/safety_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool locationEnabled = true;
  bool fallDetectionEnabled = true;
  bool healthMonitoringEnabled = true;
  bool simulationMode = true;

  final SafetyNotificationService
      notificationService =
      SafetyNotificationService.instance;

  @override
  void initState() {
    super.initState();

    loadSettings();
    notificationService.loadNotifications();
  }

  Future<void> loadSettings() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedSimulation =
        prefs.getBool('simulation_mode') ?? true;

    if (!mounted) return;

    setState(() {
      locationEnabled =
          prefs.getBool('location_enabled') ??
              true;

      fallDetectionEnabled =
          prefs.getBool(
                'fall_detection_enabled',
              ) ??
              true;

      healthMonitoringEnabled =
          prefs.getBool(
                'health_monitoring_enabled',
              ) ??
              true;

      simulationMode = savedSimulation;
    });

    await WearableService.instance
        .setSimulationMode(
      savedSimulation,
    );
  }

  Future<void> updateLocation(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'location_enabled',
      value,
    );

    setState(() {
      locationEnabled = value;
    });
  }

  Future<void> updateFallDetection(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'fall_detection_enabled',
      value,
    );

    setState(() {
      fallDetectionEnabled = value;
    });
  }

  Future<void> updateHealthMonitoring(
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'health_monitoring_enabled',
      value,
    );

    setState(() {
      healthMonitoringEnabled = value;
    });
  }

  Future<void> updateSimulationMode(
    bool value,
  ) async {
    setState(() {
      simulationMode = value;
    });

    await WearableService.instance
        .setSimulationMode(value);
  }

  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SafetyNotificationsScreen(),
      ),
    );
  }

  Future<void> createTestNotification() async {
    await notificationService.addNotification(
      title: 'Safety System Test',
      message:
          'Safety notifications are working correctly.',
      type: 'info',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Test safety notification created.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationService,
      builder: (context, child) {
        final unread =
            notificationService.unreadCount;

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
                  secondary: const Icon(
                    Icons.location_on,
                  ),
                  title: const Text(
                    'Location Services',
                  ),
                  subtitle: const Text(
                    'Allow the app to use location services',
                  ),
                  value: locationEnabled,
                  onChanged: updateLocation,
                ),
              ),

              Card(
                child: SwitchListTile(
                  secondary: const Icon(
                    Icons.warning,
                  ),
                  title: const Text(
                    'Fall Detection',
                  ),
                  subtitle: const Text(
                    'Enable wearable fall detection',
                  ),
                  value: fallDetectionEnabled,
                  onChanged:
                      updateFallDetection,
                ),
              ),

              Card(
                child: SwitchListTile(
                  secondary: const Icon(
                    Icons.favorite,
                  ),
                  title: const Text(
                    'Health Monitoring',
                  ),
                  subtitle: const Text(
                    'Enable heart rate and SpO₂ monitoring',
                  ),
                  value: healthMonitoringEnabled,
                  onChanged:
                      updateHealthMonitoring,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Safety Notifications',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: Stack(
                    clipBehavior:
                        Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications,
                        size: 32,
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -7,
                          top: -7,
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration:
                                const BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              '$unread',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: const Text(
                    'Safety Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    unread == 0
                        ? 'No unread safety alerts'
                        : '$unread unread safety alert(s)',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: openNotifications,
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.science,
                  ),
                  title: const Text(
                    'Test Notification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Create a sample safety notification',
                  ),
                  trailing: const Icon(
                    Icons.add_alert,
                  ),
                  onTap:
                      createTestNotification,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Development',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                color: simulationMode
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                child: SwitchListTile(
                  secondary: Icon(
                    simulationMode
                        ? Icons.science
                        : Icons.science_outlined,
                  ),
                  title: const Text(
                    'Simulation Mode',
                  ),
                  subtitle: Text(
                    simulationMode
                        ? 'Simulated wearable is enabled'
                        : 'Simulation is disabled',
                  ),
                  value: simulationMode,
                  onChanged:
                      updateSimulationMode,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Emergency',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.contacts,
                    size: 32,
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

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.health_and_safety,
                        size: 45,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Life Safety System',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Personal safety, emergency assistance and health monitoring system.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}