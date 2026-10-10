import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_sender/sms_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../services/emergency_history_service.dart';
import '../services/location_service.dart';
import '../services/network_service.dart';
import '../services/safety_notification_service.dart';
import 'emergency_history_screen.dart';

class SOSScreen extends StatefulWidget {
  final bool autoSend;

  const SOSScreen({
    super.key,
    this.autoSend = false,
  });

  @override
  State<SOSScreen> createState() =>
      _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool sending = false;

  bool networkAvailable = false;
  bool simAvailable = false;

  int contactCount = 0;
  String topContact = 'No contact';

  bool automaticStarted = false;

  @override
  void initState() {
    super.initState();

    loadSOSData();

    if (widget.autoSend) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted ||
            automaticStarted) {
          return;
        }

        automaticStarted = true;

        // Automatic safety triggers
        // send immediately.
        activateSOS();
      });
    }
  }

  Future<void> loadSOSData() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final savedContacts =
          prefs.getStringList(
                'emergency_contacts',
              ) ??
              [];

      int count = 0;
      String firstContact =
          'No contact';

      final validContacts =
          <Map<String, String>>[];

      for (final item in savedContacts) {
        try {
          final decoded =
              jsonDecode(item);

          final contact =
              Map<String, String>.from(
            decoded,
          );

          final name =
              contact['name']
                      ?.trim() ??
                  '';

          final phone =
              contact['phone']
                      ?.trim() ??
                  '';

          if (phone.isNotEmpty) {
            validContacts.add({
              'name': name,
              'phone': phone,
              'primary':
                  contact['primary'] ??
                      'false',
            });
          }
        } catch (e) {
          // Ignore invalid entries.
        }
      }

      count = validContacts.length;

      if (validContacts.isNotEmpty) {
        final primary =
            validContacts.where(
          (contact) =>
              contact['primary'] ==
              'true',
        );

        final selected =
            primary.isNotEmpty
                ? primary.first
                : validContacts.first;

        firstContact =
            selected['name']
                        ?.isNotEmpty ==
                    true
                ? selected['name']!
                : selected['phone']!;
      }

      bool network = false;

      try {
        network =
            await NetworkService
                .isConnected();
      } catch (e) {
        network = false;
      }

      bool sim = false;

      try {
        final sims =
            await SmsSender.getSimCards();

        sim = sims.isNotEmpty;
      } catch (e) {
        sim = false;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        contactCount = count;
        topContact = firstContact;
        networkAvailable = network;
        simAvailable = sim;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        contactCount = 0;
        topContact = 'No contact';
        networkAvailable = false;
        simAvailable = false;
      });
    }
  }

  Future<List<Map<String, String>>>
      getContacts() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final savedContacts =
        prefs.getStringList(
              'emergency_contacts',
            ) ??
            [];

    final contacts =
        <Map<String, String>>[];

    for (final item in savedContacts) {
      try {
        final decoded =
            jsonDecode(item);

        final contact =
            Map<String, String>.from(
          decoded,
        );

        final phone =
            contact['phone']
                    ?.trim() ??
                '';

        if (phone.isNotEmpty) {
          contacts.add({
            'name':
                contact['name']
                        ?.trim() ??
                    '',
            'phone': phone,
            'primary':
                contact['primary'] ??
                    'false',
          });
        }
      } catch (e) {
        // Ignore invalid entries.
      }
    }

    contacts.sort((a, b) {
      final aPrimary =
          a['primary'] == 'true';

      final bPrimary =
          b['primary'] == 'true';

      if (aPrimary && !bPrimary) {
        return -1;
      }

      if (!aPrimary && bPrimary) {
        return 1;
      }

      return 0;
    });

    return contacts;
  }

  // --------------------------------------------------
  // SEND SOS
  // --------------------------------------------------

  Future<void> activateSOS() async {
    if (sending) {
      return;
    }

    if (mounted) {
      setState(() {
        sending = true;
      });
    }

    final contacts =
        await getContacts();

    if (contacts.isEmpty) {
      await EmergencyHistoryService
          .saveEvent(
        sentCount: 0,
        failedCount: 0,
        totalContacts: 0,
        locationAvailable: false,
        status: 'FAILED',
        errorMessage:
            'No emergency contacts are configured.',
      );

      await SafetyNotificationService
          .instance
          .notifySosFailed(
        'No emergency contacts are configured.',
      );

      if (mounted) {
        setState(() {
          sending = false;
        });

        await _showFailedDialog(
          'No emergency contacts are configured.',
        );
      }

      return;
    }

    int sentCount = 0;
    int failedCount = 0;

    String? lastError;

    Position? position;

    try {
      position =
          await LocationService
              .getCurrentLocation();
    } catch (e) {
      position = null;
    }

    String message;

    if (position != null) {
      message =
          'EMERGENCY ALERT!\n'
          'I need help. Please contact me immediately.\n\n'
          'My current location:\n'
          'https://www.google.com/maps/search/?api=1'
          '&query=${position.latitude},'
          '${position.longitude}';
    } else {
      message =
          'EMERGENCY ALERT!\n'
          'I need help. Please contact me immediately.\n\n'
          'My current GPS location is unavailable.';
    }

    List<SimCard> sims = [];

    try {
      sims =
          await SmsSender.getSimCards();
    } catch (e) {
      sims = [];

      lastError =
          'Unable to access the device SIM card.';
    }

    if (sims.isEmpty) {
      await EmergencyHistoryService
          .saveEvent(
        sentCount: 0,
        failedCount: contacts.length,
        totalContacts: contacts.length,
        locationAvailable:
            position != null,
        latitude: position?.latitude,
        longitude: position?.longitude,
        status: 'FAILED',
        errorMessage:
            lastError ??
                'No active SIM card was detected.',
      );

      await SafetyNotificationService
          .instance
          .notifySosFailed(
        lastError ??
            'No active SIM card was detected.',
      );

      if (mounted) {
        setState(() {
          sending = false;
        });

        await _showFailedDialog(
          lastError ??
              'No active SIM card was detected.',
        );
      }

      return;
    }

    final selectedSimSlot =
        sims.first.simSlot;

    for (final contact in contacts) {
      final phone =
          contact['phone']?.trim();

      if (phone == null ||
          phone.isEmpty) {
        failedCount++;

        lastError =
            'One emergency contact has an invalid phone number.';

        continue;
      }

      try {
        await SmsSender.sendSms(
          phoneNumber: phone,
          message: message,
          simSlot: selectedSimSlot,
        );

        sentCount++;
      } catch (e) {
        failedCount++;

        lastError =
            'Failed to send SMS to '
            '${contact['name']?.isNotEmpty == true ? contact['name'] : phone}.';
      }
    }

    String status;

    if (sentCount == contacts.length) {
      status = 'SUCCESS';
    } else if (sentCount > 0) {
      status = 'PARTIAL';
    } else {
      status = 'FAILED';
    }

    await EmergencyHistoryService
        .saveEvent(
      sentCount: sentCount,
      failedCount: failedCount,
      totalContacts: contacts.length,
      locationAvailable:
          position != null,
      latitude: position?.latitude,
      longitude: position?.longitude,
      status: status,
      errorMessage: lastError,
    );

    if (status == 'SUCCESS') {
      await SafetyNotificationService
          .instance
          .notifySosSuccess(
        sentCount,
      );
    } else if (status == 'PARTIAL') {
      await SafetyNotificationService
          .instance
          .notifySosPartial(
        sentCount,
        failedCount,
      );
    } else {
      await SafetyNotificationService
          .instance
          .notifySosFailed(
        lastError ??
            'SOS SMS could not be sent.',
      );
    }

    await loadSOSData();

    if (!mounted) {
      return;
    }

    setState(() {
      sending = false;
    });

    // Automatic SOS does not show
    // the normal result dialog.
    if (widget.autoSend) {
      if (status == 'SUCCESS') {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            backgroundColor:
                Colors.green,
            content: Text(
              'Automatic SOS sent to $sentCount contact(s).',
            ),
          ),
        );
      } else if (status == 'PARTIAL') {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            backgroundColor:
                Colors.orange,
            content: Text(
              'SOS sent to $sentCount contact(s); '
              '$failedCount failed.',
            ),
          ),
        );
      }

      return;
    }

    if (status == 'SUCCESS') {
      await _showResultDialog(
        title: 'SOS Sent',
        message:
            'Emergency SMS was sent successfully to '
            '$sentCount contact(s).',
        color: Colors.green,
        icon: Icons.check_circle,
      );
    } else if (status == 'PARTIAL') {
      await _showResultDialog(
        title: 'SOS Partially Sent',
        message:
            'SMS was sent to $sentCount contact(s), '
            'but $failedCount failed.',
        color: Colors.orange,
        icon: Icons.warning_rounded,
        showCallButton: true,
      );
    } else {
      await _showFailedDialog(
        lastError ??
            'SOS SMS could not be sent.',
      );
    }
  }

  // --------------------------------------------------
  // CALL PRIMARY CONTACT
  // --------------------------------------------------

  Future<void> callTopContact() async {
    final contacts =
        await getContacts();

    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No emergency contacts available.',
            ),
          ),
        );
      }

      return;
    }

    final phone =
        contacts.first['phone'];

    if (phone == null ||
        phone.trim().isEmpty) {
      return;
    }

    final uri =
        Uri.parse('tel:$phone');

    try {
      final launched =
          await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the phone app.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the phone app.',
            ),
          ),
        );
      }
    }
  }

  // --------------------------------------------------
  // RESULT DIALOG
  // --------------------------------------------------

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
    bool showCallButton = false,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            if (showCallButton)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  callTopContact();
                },
                child:
                    const Text('CALL CONTACT'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFailedDialog(
    String reason,
  ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.red,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('SOS Failed'),
              ),
            ],
          ),
          content: Text(
            '$reason\n\n'
            'You can try calling your primary emergency contact.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                callTopContact();
              },
              child:
                  const Text('CALL CONTACT'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EmergencyHistoryScreen(),
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Emergency SOS'),
        actions: [
          IconButton(
            onPressed: openHistory,
            tooltip:
                'Emergency History',
            icon:
                const Icon(Icons.history),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadSOSData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              Icon(
                sending
                    ? Icons.sos
                    : Icons.warning_rounded,
                size: 85,
                color: Colors.red,
              ),

              const SizedBox(height: 15),

              const Text(
                'Emergency SOS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Send an emergency alert to your trusted contacts.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 25),

              _buildStatusCard(),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // SEND SOS BUTTON
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 170,
                child: ElevatedButton(
                  onPressed:
                      sending
                          ? null
                          : activateSOS,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 50,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        sending
                            ? 'SENDING SOS...'
                            : 'SEND SOS ALERT',
                        style:
                            const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // CALL PRIMARY CONTACT BUTTON
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed:
                      sending
                          ? null
                          : callTopContact,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.green,
                    side:
                        const BorderSide(
                      color: Colors.green,
                      width: 1.5,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.phone,
                    size: 26,
                  ),
                  label: const Text(
                    'CALL PRIMARY CONTACT',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              if (sending)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    bottom: 18,
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Colors.red,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Sending emergency alerts...',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              _buildSafetyInfo(),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed:
                    openHistory,
                icon: const Icon(
                  Icons.history,
                ),
                label: const Text(
                  'View Emergency History',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            _statusRow(
              icon:
                  networkAvailable
                      ? Icons.wifi
                      : Icons.wifi_off,
              title: 'Internet',
              value:
                  networkAvailable
                      ? 'Available'
                      : 'Unavailable',
              color:
                  networkAvailable
                      ? Colors.green
                      : Colors.orange,
            ),
            const Divider(
              height: 22,
            ),
            _statusRow(
              icon:
                  simAvailable
                      ? Icons.sim_card
                      : Icons.sim_card_alert,
              title: 'SIM Card',
              value:
                  simAvailable
                      ? 'Available'
                      : 'Unavailable',
              color:
                  simAvailable
                      ? Colors.green
                      : Colors.red,
            ),
            const Divider(
              height: 22,
            ),
            _statusRow(
              icon:
                  Icons.contact_phone,
              title:
                  'Emergency Contacts',
              value:
                  '$contactCount',
              color:
                  contactCount > 0
                      ? Colors.green
                      : Colors.red,
            ),
            const Divider(
              height: 22,
            ),
            _statusRow(
              icon: Icons.person,
              title: 'Primary Contact',
              value: topContact,
              color:
                  contactCount > 0
                      ? Colors.green
                      : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                TextStyle(
              color: color,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyInfo() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
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
                Icons.shield,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                'Fail-Safe Emergency System',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Automatic safety triggers send the SOS directly without waiting for the user.',
            style: TextStyle(
              height: 1.45,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'The app attempts to send the emergency alert to every configured contact.',
            style: TextStyle(
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}