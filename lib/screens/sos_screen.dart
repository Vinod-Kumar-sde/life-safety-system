import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  List<Map<String, String>> contacts = [];
  bool loadingLocation = false;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedContacts =
        prefs.getStringList('emergency_contacts') ?? [];

    setState(() {
      contacts = savedContacts.map((contact) {
        final data = jsonDecode(contact);

        return {
          'name': data['name'].toString(),
          'phone': data['phone'].toString(),
        };
      }).toList();
    });
  }

  Future<void> callEmergencyContact() async {
    if (contacts.isEmpty) {
      showMessage('No emergency contacts have been added.');
      return;
    }

    final phone = contacts.first['phone']!;
    final callUri = Uri.parse('tel:$phone');

    try {
      final launched = await launchUrl(
        callUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        showMessage('Unable to open phone dialer.');
      }
    } catch (e) {
      showMessage('Unable to open phone dialer.');
    }
  }

  Future<void> activateSOS() async {
    if (contacts.isEmpty) {
      showMessage('No emergency contacts have been added.');
      return;
    }

    setState(() {
      loadingLocation = true;
    });

    final position = await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      loadingLocation = false;
    });

    if (position == null) {
      showLocationFailureDialog();
      return;
    }

    final latitude = position.latitude;
    final longitude = position.longitude;

    final message =
        'SOS! I need help. My current location is:\n'
        'https://www.google.com/maps/search/?api=1&query='
        '$latitude,$longitude';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Send SOS?'),
          content: Text(
            'SOS will alert ${contacts.length} emergency '
            'contact(s).\n\n'
            'Location:\n'
            '$latitude, $longitude\n\n'
            'SMS will open with the emergency message.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await sendSOSMessage(
                  contacts.first['phone']!,
                  message,
                );
              },
              child: const Text('SEND SOS'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendSOSMessage(
    String phone,
    String message,
  ) async {
    final smsUri = Uri.parse(
      'sms:$phone?body=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        showMessage(
          'Unable to open SMS app. Please call the emergency contact.',
        );
      }
    } catch (e) {
      showMessage(
        'SMS could not be opened. Please call the emergency contact.',
      );
    }
  }

  void showLocationFailureDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location Unavailable'),
          content: const Text(
            'Your current location could not be obtained.\n\n'
            'Please check that Location is turned on and '
            'permission is allowed.\n\n'
            'You can still call your emergency contact.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CLOSE'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                callEmergencyContact();
              },
              icon: const Icon(Icons.call),
              label: const Text('CALL'),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            GestureDetector(
              onTap: loadingLocation ? null : activateSOS,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: loadingLocation
                      ? Colors.grey
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: loadingLocation
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
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
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: callEmergencyContact,
              icon: const Icon(Icons.call),
              label: const Text(
                'Call Emergency Contact',
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (contacts.isEmpty)
              const Text(
                'No emergency contacts added.',
                style: TextStyle(fontSize: 16),
              ),

            ...contacts.map(
              (contact) => Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(contact['name']!),
                  subtitle: Text(contact['phone']!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}