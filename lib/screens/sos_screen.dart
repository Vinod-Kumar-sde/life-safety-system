import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_sender/sms_sender.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../services/network_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  List<Map<String, String>> emergencyContacts = [];

  bool loading = false;
  bool internetAvailable = false;

  List<SimCard> simCards = [];
  int? selectedSimSlot;

  @override
  void initState() {
    super.initState();

    loadContacts();
    checkNetwork();
    detectSim();
  }

  // ==========================
  // LOAD CONTACTS
  // ==========================

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final savedContacts =
        prefs.getStringList('emergency_contacts');

    final loadedContacts = <Map<String, String>>[];

    if (savedContacts != null) {
      for (final contact in savedContacts) {
        try {
          final decoded =
              jsonDecode(contact) as Map<String, dynamic>;

          loadedContacts.add({
            'name': decoded['name']?.toString() ?? '',
            'phone': decoded['phone']?.toString() ?? '',
          });
        } catch (e) {
          print('CONTACT LOAD ERROR: $e');
        }
      }
    }

    if (!mounted) return;

    setState(() {
      emergencyContacts = loadedContacts;
    });
  }

  // ==========================
  // DETECT SIM
  // ==========================

  Future<void> detectSim() async {
    try {
      final detectedSims =
          await SmsSender.getSimCards();

      print('DETECTED SIMS: $detectedSims');

      if (!mounted) return;

      setState(() {
        simCards = detectedSims;

        if (detectedSims.isNotEmpty) {
          selectedSimSlot =
              detectedSims.first.simSlot;
        } else {
          selectedSimSlot = null;
        }
      });
    } catch (e) {
      print('SIM DETECTION ERROR: $e');

      if (!mounted) return;

      setState(() {
        simCards = [];
        selectedSimSlot = null;
      });
    }
  }

  // ==========================
  // NETWORK
  // ==========================

  Future<void> checkNetwork() async {
    final connected =
        await NetworkService.isConnected();

    if (!mounted) return;

    setState(() {
      internetAvailable = connected;
    });
  }

  // ==========================
  // MAIN SOS
  // ==========================

  Future<void> activateSOS() async {
    if (loading) return;

    await loadContacts();
    await detectSim();

    if (emergencyContacts.isEmpty) {
      showError(
        'No emergency contacts found.\n'
        'Please add at least one emergency contact.',
      );
      return;
    }

    if (selectedSimSlot == null) {
      showError(
        'No active SIM detected by the SMS service.\n\n'
        'Please make sure your SIM is enabled and can send normal SMS messages.',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final position =
        await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (position == null) {
      setState(() {
        loading = false;
      });

      showLocationFailure();
      return;
    }

    await sendEmergencySMS(
      position.latitude,
      position.longitude,
    );
  }

  // ==========================
  // SEND SMS
  // ==========================

  Future<void> sendEmergencySMS(
    double latitude,
    double longitude,
  ) async {
    final locationLink =
        'https://www.google.com/maps/search/?api=1'
        '&query=$latitude,$longitude';

    final message =
        'SOS! I need help.\n'
        'My current location:\n'
        '$locationLink';

    int sentCount = 0;
    int failedCount = 0;

    for (final contact in emergencyContacts) {
      final phone = contact['phone'];

      if (phone == null || phone.isEmpty) {
        failedCount++;
        continue;
      }

      try {
        print(
          'SENDING SMS TO $phone '
          'USING SIM SLOT $selectedSimSlot',
        );

        final result = await SmsSender.sendSms(
          phoneNumber: phone,
          message: message,
          simSlot: selectedSimSlot!,
        );

        print(
          'SMS SUCCESS FOR $phone: $result',
        );

        sentCount++;
      } catch (e) {
        failedCount++;

        print(
          'SMS ERROR FOR $phone: $e',
        );

        if (mounted) {
          showError(
            'SMS failed for $phone\n\n'
            'Error: $e',
          );
        }
      }
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (sentCount == emergencyContacts.length) {
      showSuccess(
        'SOS sent successfully to '
        '$sentCount contact(s).',
      );
    } else if (sentCount > 0) {
      showError(
        'SOS sent to $sentCount contact(s), '
        'but $failedCount failed.',
      );
    } else {
      showError(
        'SOS could not be sent.\n'
        'Check the SMS error shown above.',
      );
    }
  }

  // ==========================
  // LOCATION FAILURE
  // ==========================

  void showLocationFailure() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Location Unavailable',
          ),

          content: const Text(
            'GPS location could not be obtained.\n\n'
            'You can still send the emergency SMS without location.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.pop(context);

                sendEmergencySMSWithoutLocation();
              },

              child: const Text(
                'SEND SOS ANYWAY',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================
  // SEND WITHOUT GPS
  // ==========================

  Future<void> sendEmergencySMSWithoutLocation() async {
    if (selectedSimSlot == null) {
      await detectSim();
    }

    if (selectedSimSlot == null) {
      showError(
        'No active SIM detected by the SMS service.',
      );
      return;
    }

    const message =
        'SOS! I need help. '
        'My current location could not be obtained.';

    setState(() {
      loading = true;
    });

    int sentCount = 0;
    int failedCount = 0;

    for (final contact in emergencyContacts) {
      final phone = contact['phone'];

      if (phone == null || phone.isEmpty) {
        failedCount++;
        continue;
      }

      try {
        final result = await SmsSender.sendSms(
          phoneNumber: phone,
          message: message,
          simSlot: selectedSimSlot!,
        );

        print(
          'SMS SUCCESS FOR $phone: $result',
        );

        sentCount++;
      } catch (e) {
        failedCount++;

        print(
          'SMS ERROR FOR $phone: $e',
        );

        if (mounted) {
          showError(
            'SMS failed for $phone\n\n'
            'Error: $e',
          );
        }
      }
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (sentCount > 0) {
      showSuccess(
        'SOS sent to $sentCount contact(s).',
      );
    } else {
      showError(
        'SOS could not be sent.',
      );
    }
  }

  // ==========================
  // CALL TOP CONTACT
  // ==========================

  Future<void> callTopContact() async {
    await loadContacts();

    if (emergencyContacts.isEmpty) {
      showError(
        'No emergency contact available.',
      );
      return;
    }

    final phone =
        emergencyContacts.first['phone'];

    if (phone == null || phone.isEmpty) {
      showError(
        'Top contact has no valid phone number.',
      );
      return;
    }

    final phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final launched =
          await launchUrl(phoneUri);

      if (!launched && mounted) {
        showError(
          'Unable to open phone dialer.',
        );
      }
    } catch (e) {
      print('CALL ERROR: $e');

      if (mounted) {
        showError(
          'Unable to call emergency contact.\n'
          'Error: $e',
        );
      }
    }
  }

  // ==========================
  // SUCCESS
  // ==========================

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================
  // ERROR
  // ==========================

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContacts =
        emergencyContacts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency SOS',
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await loadContacts();
          await checkNetwork();
          await detectSim();
        },

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.warning,
                size: 90,
                color: Colors.red,
              ),

              const SizedBox(height: 20),

              const Text(
                'Emergency SOS',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Press SOS to immediately send an emergency message with your current location to all emergency contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              // SOS BUTTON
              SizedBox(
                width: double.infinity,
                height: 150,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(25),
                    ),
                  ),

                  onPressed:
                      loading ? null : activateSOS,

                  child: loading
                      ? const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),

                            SizedBox(height: 10),

                            Text(
                              'SENDING SOS...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sos,
                              size: 55,
                            ),

                            SizedBox(height: 8),

                            Text(
                              'SEND SOS',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // CALL BUTTON
              SizedBox(
                height: 45,

                child: OutlinedButton.icon(
                  onPressed:
                      loading || !hasContacts
                          ? null
                          : callTopContact,

                  icon: const Icon(
                    Icons.call,
                    size: 19,
                  ),

                  label: const Text(
                    'CALL TOP CONTACT',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.green,

                    side: const BorderSide(
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // NETWORK
              Card(
                child: ListTile(
                  leading: Icon(
                    internetAvailable
                        ? Icons.wifi
                        : Icons.wifi_off,
                    color: internetAvailable
                        ? Colors.green
                        : Colors.orange,
                  ),

                  title: const Text(
                    'Network Status',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    internetAvailable
                        ? 'Internet available'
                        : 'Internet unavailable',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SIM STATUS
              Card(
                child: ListTile(
                  leading: Icon(
                    simCards.isNotEmpty
                        ? Icons.sim_card
                        : Icons
                            .sim_card_alert,
                    color: simCards.isNotEmpty
                        ? Colors.green
                        : Colors.red,
                  ),

                  title: const Text(
                    'SIM Status',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    simCards.isNotEmpty
                        ? 'SIM detected • Slot ${selectedSimSlot! + 1}'
                        : 'No SIM detected by SMS service',
                  ),

                  trailing:
                      simCards.isNotEmpty
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : null,
                ),
              ),

              const SizedBox(height: 10),

              // CONTACT STATUS
              Card(
                child: ListTile(
                  leading: Icon(
                    hasContacts
                        ? Icons.contacts
                        : Icons
                            .contact_phone_outlined,
                    color: hasContacts
                        ? Colors.green
                        : Colors.red,
                  ),

                  title: const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    hasContacts
                        ? '${emergencyContacts.length} contact(s) configured'
                        : 'No contacts configured',
                  ),

                  trailing: hasContacts
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 15),

              // TOP CONTACT
              if (hasContacts)
                Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(
                      child:
                          Icon(Icons.person),
                    ),

                    title: Text(
                      emergencyContacts.first[
                              'name'] ??
                          'Emergency Contact',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      emergencyContacts.first[
                              'phone'] ??
                          '',
                    ),

                    trailing:
                        const Icon(
                      Icons.call,
                      color: Colors.green,
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              // INFO
              Card(
                color: Colors.red.shade50,

                child: const Padding(
                  padding: EdgeInsets.all(16),

                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red,
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'SEND SOS sends the emergency SMS to every saved emergency contact using the detected SIM.',
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
  }
}