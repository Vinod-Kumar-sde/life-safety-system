import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/safety_notification.dart';

class SafetyNotificationService extends ChangeNotifier {
  SafetyNotificationService._();

  static final SafetyNotificationService instance =
      SafetyNotificationService._();

  static const String _key = 'safety_notifications';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<SafetyNotification> notifications = [];

  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) {
      return;
    }

    await loadNotifications();

    if (Platform.isAndroid) {
      const androidSettings =
          AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initializationSettings =
          InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(
        settings: initializationSettings,
      );

      final androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();

        const channel =
            AndroidNotificationChannel(
          'life_safety_alerts',
          'Life Safety Alerts',
          description:
              'Emergency and health safety notifications.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await androidPlugin.createNotificationChannel(
          channel,
        );
      }
    }

    initialized = true;

    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList(_key) ?? [];

    notifications = [];

    for (final item in saved) {
      try {
        final decoded = jsonDecode(item);

        notifications.add(
          SafetyNotification.fromJson(
            Map<String, dynamic>.from(
              decoded,
            ),
          ),
        );
      } catch (e) {
        // Ignore corrupted entries.
      }
    }

    notifications.sort(
      (a, b) => b.timestamp.compareTo(
        a.timestamp,
      ),
    );

    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    if (!initialized) {
      await initialize();
    }

    final notification =
        SafetyNotification(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      timestamp: DateTime.now(),
      title: title,
      message: message,
      type: type,
      isRead: false,
    );

    notifications.insert(
      0,
      notification,
    );

    if (notifications.length > 50) {
      notifications =
          notifications.take(50).toList();
    }

    await _saveNotifications();

    await _showPhoneNotification(
      notification,
    );

    notifyListeners();
  }

  Future<void> _showPhoneNotification(
    SafetyNotification notification,
  ) async {
    if (!Platform.isAndroid) {
      return;
    }

    final notificationId =
        DateTime.now()
                .millisecondsSinceEpoch %
            2147483647;

    const androidDetails =
        AndroidNotificationDetails(
      'life_safety_alerts',
      'Life Safety Alerts',
      channelDescription:
          'Emergency and health safety notifications.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const details =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: notificationId,
      title: notification.title,
      body: notification.message,
      notificationDetails: details,
      payload: notification.id,
    );
  }

  Future<void> _saveNotifications() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        notifications.map(
      (notification) {
        return jsonEncode(
          notification.toJson(),
        );
      },
    ).toList();

    await prefs.setStringList(
      _key,
      saved,
    );
  }

  Future<void> markAsRead(
    String id,
  ) async {
    final index =
        notifications.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return;
    }

    notifications[index] =
        notifications[index].copyWith(
      isRead: true,
    );

    await _saveNotifications();

    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    notifications =
        notifications.map(
      (notification) {
        return notification.copyWith(
          isRead: true,
        );
      },
    ).toList();

    await _saveNotifications();

    notifyListeners();
  }

  Future<void> deleteNotification(
    String id,
  ) async {
    notifications.removeWhere(
      (item) => item.id == id,
    );

    await _saveNotifications();

    notifyListeners();
  }

  Future<void> clearNotifications() async {
    notifications.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_key);

    notifyListeners();
  }

  Future<void> clearAll() async {
    await clearNotifications();
  }

  int get unreadCount {
    return notifications
        .where(
          (notification) =>
              !notification.isRead,
        )
        .length;
  }

  Future<void> notifyFallDetected() async {
    await addNotification(
      title: 'Fall Detected',
      message:
          'A possible fall was detected by the wearable.',
      type: 'fall',
    );
  }

  Future<void> notifyLowBattery(
    int battery,
  ) async {
    await addNotification(
      title: 'Low Wearable Battery',
      message:
          'Wearable battery is at $battery%.',
      type: 'battery',
    );
  }

  Future<void> notifyAbnormalHeartRate(
    int heartRate,
  ) async {
    await addNotification(
      title: 'Abnormal Heart Rate',
      message:
          'Heart rate reading: $heartRate BPM.',
      type: 'health',
    );
  }

  Future<void> notifyLowSpo2(
    int spo2,
  ) async {
    await addNotification(
      title: 'Low SpO₂',
      message:
          'SpO₂ reading: $spo2%.',
      type: 'health',
    );
  }

  Future<void> notifySafeZoneExit(
    double distance,
    double radius,
  ) async {
    await addNotification(
      title: 'Safe Zone Exit',
      message:
          'You are ${distance.toStringAsFixed(0)} m from your Safe Zone. '
          'The allowed radius is ${radius.toStringAsFixed(0)} m.',
      type: 'safe_zone',
    );
  }

  Future<void> notifyInactivity() async {
    await addNotification(
      title: 'Inactivity Alert',
      message:
          'No wearable activity has been detected for an extended period. '
          'Please check on the person.',
      type: 'inactivity',
    );
  }

  Future<void> notifySosSuccess(
    int sentCount,
  ) async {
    await addNotification(
      title: 'SOS Sent',
      message:
          'Emergency SMS sent to $sentCount contact(s).',
      type: 'sos',
    );
  }

  Future<void> notifySosPartial(
    int sentCount,
    int failedCount,
  ) async {
    await addNotification(
      title: 'SOS Partially Sent',
      message:
          '$sentCount SMS sent, $failedCount failed.',
      type: 'sos',
    );
  }

  Future<void> notifySosFailed(
    String reason,
  ) async {
    await addNotification(
      title: 'SOS Failed',
      message: reason,
      type: 'sos',
    );
  }

  Future<void> showTestNotification() async {
    await addNotification(
      title: 'Life Safety Test',
      message:
          'Phone notifications are working correctly.',
      type: 'info',
    );
  }
}