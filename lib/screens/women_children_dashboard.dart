import 'package:flutter/material.dart';

import 'mode_selection_screen.dart';
import 'settings_screen.dart';
import 'sos_screen.dart';
import 'location_screen.dart';
import 'contacts_screen.dart';
import 'wearable_screen.dart';
import 'safe_zone_screen.dart';

class WomenChildrenDashboard extends StatefulWidget {
  const WomenChildrenDashboard({super.key});

  @override
  State<WomenChildrenDashboard> createState() =>
      _WomenChildrenDashboardState();
}

class _WomenChildrenDashboardState
    extends State<WomenChildrenDashboard> {
  Future<void> refreshDashboard() async {
    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ModeSelectionScreen(),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Women & Children',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Safety Dashboard',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
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
          onRefresh: refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: Colors.pink.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Safe',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your emergency tools are ready whenever you need them.',
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.swipe_down,
                              color: Colors.pink,
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Pull down to refresh',
                              style: TextStyle(
                                color: Colors.pink,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

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
                      'Contacts',
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
                    _quickButton(
                      context,
                      Icons.call,
                      'Emergency',
                      Colors.red,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SOSScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                _optionCard(
                  context,
                  Icons.location_on,
                  'Live Location',
                  'View your current location',
                  Colors.pink,
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

                _optionCard(
                  context,
                  Icons.contacts,
                  'Emergency Contacts',
                  'Manage trusted contacts',
                  Colors.pink,
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

                // Safe Zone
                _optionCard(
                  context,
                  Icons.shield,
                  'Safe Zone',
                  'Safety zone and location protection',
                  Colors.pink,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SafeZoneScreen(),
                      ),
                    );
                  },
                ),

                _optionCard(
                  context,
                  Icons.watch,
                  'Wearable',
                  'Check wearable connection and status',
                  Colors.pink,
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
                  color: Colors.pink.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.pink,
                          size: 30,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your safety features are available from this dashboard.',
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
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Icon(
          icon,
          color: color,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 17,
        ),
        onTap: onTap,
      ),
    );
  }
}