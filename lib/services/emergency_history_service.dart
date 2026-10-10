import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_history.dart';

class EmergencyHistoryService {
  static const String _key = 'emergency_history';

  static Future<List<EmergencyHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final savedHistory =
        prefs.getStringList(_key);

    if (savedHistory == null) {
      return [];
    }

    return savedHistory
        .map(
          (item) => EmergencyHistory.fromJson(
            jsonDecode(item),
          ),
        )
        .toList()
        .reversed
        .toList();
  }

  static Future<void> saveEvent({
    required int sentCount,
    required int failedCount,
    required int totalContacts,
    required bool locationAvailable,
    double? latitude,
    double? longitude,
    required String status,
    String? errorMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final existing =
        prefs.getStringList(_key) ?? [];

    final event = EmergencyHistory(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      timestamp: DateTime.now(),
      sentCount: sentCount,
      failedCount: failedCount,
      totalContacts: totalContacts,
      locationAvailable: locationAvailable,
      latitude: latitude,
      longitude: longitude,
      status: status,
      errorMessage: errorMessage,
    );

    existing.add(
      jsonEncode(event.toJson()),
    );

    await prefs.setStringList(
      _key,
      existing,
    );
  }

  static Future<void> deleteEvent(
    String id,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final existing =
        prefs.getStringList(_key) ?? [];

    existing.removeWhere((item) {
      final json = jsonDecode(item);
      return json['id'] == id;
    });

    await prefs.setStringList(
      _key,
      existing,
    );
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}