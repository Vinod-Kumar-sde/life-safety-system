import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_history.dart';
import '../services/emergency_history_service.dart';

class EmergencyHistoryScreen extends StatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  State<EmergencyHistoryScreen> createState() =>
      _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState
    extends State<EmergencyHistoryScreen> {
  List<EmergencyHistory> history = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      loading = true;
    });

    final data =
        await EmergencyHistoryService.getHistory();

    if (!mounted) return;

    setState(() {
      history = data;
      loading = false;
    });
  }

  Future<void> deleteEvent(
    EmergencyHistory event,
  ) async {
    await EmergencyHistoryService.deleteEvent(
      event.id,
    );

    await loadHistory();
  }

  Future<void> clearAll() async {
    if (history.isEmpty) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content: const Text(
            'All emergency history records will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('CLEAR'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await EmergencyHistoryService.clearHistory();

    await loadHistory();
  }

  Future<void> openLocation(
    EmergencyHistory event,
  ) async {
    if (event.latitude == null ||
        event.longitude == null) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${event.latitude},${event.longitude}',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(
    BuildContext context,
    DateTime date,
  ) {
    return TimeOfDay.fromDateTime(date)
        .format(context);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return Colors.green;

      case 'PARTIAL':
        return Colors.orange;

      default:
        return Colors.red;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'SUCCESS':
        return Icons.check_circle;

      case 'PARTIAL':
        return Icons.warning;

      default:
        return Icons.error;
    }
  }

  String statusText(String status) {
    switch (status) {
      case 'SUCCESS':
        return 'SOS SENT';

      case 'PARTIAL':
        return 'PARTIALLY SENT';

      default:
        return 'SOS FAILED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency History',
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed: clearAll,
              icon: const Icon(
                Icons.delete_sweep,
              ),
              tooltip: 'Clear History',
            ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : history.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadHistory,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 150),
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'No emergency history',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'SOS events will appear here.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadHistory,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final event = history[index];

                      final color =
                          statusColor(event.status);

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    statusIcon(
                                      event.status,
                                    ),
                                    color: color,
                                    size: 30,
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          statusText(
                                            event.status,
                                          ),
                                          style:
                                              TextStyle(
                                            color: color,
                                            fontSize: 17,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(
                                          '${formatDate(event.timestamp)} • '
                                          '${formatTime(context, event.timestamp)}',
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      deleteEvent(
                                        event,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons
                                          .delete_outline,
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(
                                height: 25,
                              ),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.sms,
                                    size: 20,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Text(
                                    'SMS Sent: '
                                    '${event.sentCount} / '
                                    '${event.totalContacts}',
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              Row(
                                children: [
                                  Icon(
                                    event.locationAvailable
                                        ? Icons
                                            .location_on
                                        : Icons
                                            .location_off,
                                    size: 20,
                                    color: event
                                            .locationAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Text(
                                    event.locationAvailable
                                        ? 'Location Available'
                                        : 'Location Unavailable',
                                  ),
                                ],
                              ),

                              if (event.latitude !=
                                      null &&
                                  event.longitude !=
                                      null) ...[
                                const SizedBox(
                                  height: 12,
                                ),

                                SizedBox(
                                  width:
                                      double.infinity,
                                  child:
                                      OutlinedButton
                                          .icon(
                                    onPressed: () {
                                      openLocation(
                                        event,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.map,
                                    ),
                                    label: const Text(
                                      'VIEW LOCATION',
                                    ),
                                  ),
                                ),
                              ],

                              if (event.failedCount >
                                  0) ...[
                                const SizedBox(
                                  height: 10,
                                ),

                                Text(
                                  'Failed: '
                                  '${event.failedCount}',
                                  style:
                                      const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
