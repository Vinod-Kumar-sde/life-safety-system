import 'package:flutter/material.dart';

import '../models/safety_notification.dart';
import '../services/safety_notification_service.dart';

class SafetyNotificationsScreen extends StatefulWidget {
  const SafetyNotificationsScreen({
    super.key,
  });

  @override
  State<SafetyNotificationsScreen> createState() =>
      _SafetyNotificationsScreenState();
}

class _SafetyNotificationsScreenState
    extends State<SafetyNotificationsScreen> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'SOS',
    'Health',
    'Fall',
    'Safe Zone',
    'Battery',
  ];

  @override
  void initState() {
    super.initState();

    SafetyNotificationService.instance
        .loadNotifications();
  }

  List<SafetyNotification> get filteredNotifications {
    final notifications =
        SafetyNotificationService.instance.notifications;

    if (selectedFilter == 'All') {
      return notifications;
    }

    return notifications.where((notification) {
      switch (selectedFilter) {
        case 'SOS':
          return notification.type == 'sos';

        case 'Health':
          return notification.type == 'health';

        case 'Fall':
          return notification.type == 'fall';

        case 'Safe Zone':
          return notification.type == 'safe_zone';

        case 'Battery':
          return notification.type == 'battery';

        default:
          return true;
      }
    }).toList();
  }

  Future<void> _markAllAsRead() async {
    await SafetyNotificationService.instance
        .markAllAsRead();
  }

  Future<void> _deleteNotification(
    SafetyNotification notification,
  ) async {
    await SafetyNotificationService.instance
        .deleteNotification(
      notification.id,
    );
  }

  Future<void> _clearAll() async {
    if (SafetyNotificationService
        .instance
        .notifications
        .isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Clear All Notifications?',
          ),
          content: const Text(
            'All safety notifications will be permanently removed.',
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
              child: const Text('CLEAR ALL'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await SafetyNotificationService.instance
          .clearAll();
    }
  }

  String _typeLabel(
    String type,
  ) {
    switch (type) {
      case 'sos':
        return 'SOS';

      case 'health':
        return 'HEALTH';

      case 'fall':
        return 'FALL';

      case 'safe_zone':
        return 'SAFE ZONE';

      case 'battery':
        return 'BATTERY';

      default:
        return 'INFO';
    }
  }

  IconData _typeIcon(
    String type,
  ) {
    switch (type) {
      case 'sos':
        return Icons.sos;

      case 'health':
        return Icons.favorite;

      case 'fall':
        return Icons.warning_rounded;

      case 'safe_zone':
        return Icons.location_on;

      case 'battery':
        return Icons.battery_alert;

      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(
    String type,
  ) {
    switch (type) {
      case 'sos':
        return Colors.red;

      case 'health':
        return Colors.pink;

      case 'fall':
        return Colors.orange;

      case 'safe_zone':
        return Colors.blue;

      case 'battery':
        return Colors.amber.shade800;

      default:
        return Colors.grey;
    }
  }

  String _timeText(
    DateTime timestamp,
  ) {
    final difference =
        DateTime.now().difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} day(s) ago';
    }

    final day =
        timestamp.day.toString().padLeft(2, '0');

    final month =
        timestamp.month.toString().padLeft(2, '0');

    final year =
        timestamp.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safety Notifications',
        ),
        actions: [
          ListenableBuilder(
            listenable:
                SafetyNotificationService.instance,
            builder: (context, _) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'read') {
                    _markAllAsRead();
                  } else if (value == 'clear') {
                    _clearAll();
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(
                            Icons.done_all,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Mark all as read',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Clear all',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable:
            SafetyNotificationService.instance,
        builder: (context, _) {
          final service =
              SafetyNotificationService.instance;

          final notifications =
              filteredNotifications;

          return RefreshIndicator(
            onRefresh: service.loadNotifications,
            child: Column(
              children: [
                _buildHeader(
                  service,
                ),

                _buildFilters(),

                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount:
                              notifications.length,
                          itemBuilder:
                              (context, index) {
                            return _buildNotificationCard(
                              notifications[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    SafetyNotificationService service,
  ) {
    final total =
        service.notifications.length;

    final unread =
        service.unreadCount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.12),
            Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.04),
          ],
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Center',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No notifications'
                      : '$total notification(s) • $unread unread',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter =
              filters[index];

          final selected =
              selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() {
                selectedFilter = filter;
              });
            },
            avatar: filter == 'All'
                ? const Icon(
                    Icons.apps,
                    size: 17,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    SafetyNotification notification,
  ) {
    final color =
        _typeColor(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction:
          DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        alignment:
            Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'Delete Notification?',
                  ),
                  content: const Text(
                    'This notification will be removed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          false,
                        );
                      },
                      child:
                          const Text('CANCEL'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          true,
                        );
                      },
                      child:
                          const Text('DELETE'),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) {
        _deleteNotification(
          notification,
        );
      },
      child: Card(
        elevation:
            notification.isRead ? 0 : 2,
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
          side: BorderSide(
            color: notification.isRead
                ? Colors.grey.shade200
                : color.withOpacity(0.25),
          ),
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () {
            if (!notification.isRead) {
              SafetyNotificationService
                  .instance
                  .markAsRead(
                notification.id,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _typeIcon(
                      notification.type,
                    ),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    notification
                                            .isRead
                                        ? FontWeight
                                            .w600
                                        : FontWeight
                                            .bold,
                              ),
                            ),
                          ),
                          if (!notification
                              .isRead)
                            Container(
                              width: 9,
                              height: 9,
                              decoration:
                                  BoxDecoration(
                                color: color,
                                shape: BoxShape
                                    .circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              color: color
                                  .withOpacity(
                                0.10,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                6,
                              ),
                            ),
                            child: Text(
                              _typeLabel(
                                notification.type,
                              ),
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _timeText(
                              notification
                                  .timestamp,
                            ),
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            padding:
                                EdgeInsets.zero,
                            iconSize: 20,
                            onSelected: (value) {
                              if (value ==
                                  'read') {
                                SafetyNotificationService
                                    .instance
                                    .markAsRead(
                                  notification.id,
                                );
                              } else if (value ==
                                  'delete') {
                                _deleteNotification(
                                  notification,
                                );
                              }
                            },
                            itemBuilder:
                                (context) {
                              return [
                                if (!notification
                                    .isRead)
                                  const PopupMenuItem(
                                    value: 'read',
                                    child: Text(
                                      'Mark as read',
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(
          Icons.notifications_none,
          size: 72,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            selectedFilter == 'All'
                ? 'No safety notifications'
                : 'No $selectedFilter notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Text(
              selectedFilter == 'All'
                  ? 'Safety alerts will appear here when something important happens.'
                  : 'There are no notifications in this category yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}