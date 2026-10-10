import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'safety_notification_service.dart';

class WearableService extends ChangeNotifier {
  WearableService._();

  static final WearableService instance =
      WearableService._();

  bool connected = false;

  int heartRate = 72;
  int spo2 = 98;
  int battery = 100;

  bool fallDetected = false;

  BluetoothDevice? device;

  bool simulationMode = true;

  bool fallAlertActive = false;
  bool lowBatteryAlertActive = false;
  bool abnormalHeartRateAlertActive = false;
  bool lowSpo2AlertActive = false;

  bool inactivityAlertActive = false;
  bool inactivitySosTriggered = false;

  bool inactivityMonitoringEnabled = true;

  // Available inactivity limits:
  // 6, 12, 16, 24 and 48 hours.
  int inactivityLimitHours = 24;

  DateTime? lastActivityTime;
  DateTime? lastInactivityNotificationTime;

  Timer? _inactivityTimer;

  int sleepStartHour = 22;
  int sleepStartMinute = 0;

  int sleepEndHour = 8;
  int sleepEndMinute = 0;

  static const String _simulationKey =
      'simulation_mode';

  static const String _inactivityEnabledKey =
      'inactivity_monitoring_enabled';

  static const String _inactivityLimitHoursKey =
      'inactivity_limit_hours';

  static const String _sleepStartHourKey =
      'sleep_start_hour';

  static const String _sleepStartMinuteKey =
      'sleep_start_minute';

  static const String _sleepEndHourKey =
      'sleep_end_hour';

  static const String _sleepEndMinuteKey =
      'sleep_end_minute';

  Future<void> loadSimulationMode() async {
    final prefs =
        await SharedPreferences.getInstance();

    simulationMode =
        prefs.getBool(_simulationKey) ?? true;

    await loadInactivitySettings();

    if (!simulationMode) {
      connected = false;
      fallDetected = false;
      _stopInactivityMonitoring();
    }

    notifyListeners();
  }

  Future<void> loadInactivitySettings() async {
    final prefs =
        await SharedPreferences.getInstance();

    inactivityMonitoringEnabled =
        prefs.getBool(
              _inactivityEnabledKey,
            ) ??
            true;

    inactivityLimitHours =
        prefs.getInt(
              _inactivityLimitHoursKey,
            ) ??
            24;

    // Support the new 6-hour option.
    if (![6, 12, 16, 24, 48]
        .contains(inactivityLimitHours)) {
      inactivityLimitHours = 24;
    }

    sleepStartHour =
        prefs.getInt(
              _sleepStartHourKey,
            ) ??
            22;

    sleepStartMinute =
        prefs.getInt(
              _sleepStartMinuteKey,
            ) ??
            0;

    sleepEndHour =
        prefs.getInt(
              _sleepEndHourKey,
            ) ??
            8;

    sleepEndMinute =
        prefs.getInt(
              _sleepEndMinuteKey,
            ) ??
            0;
  }

  Future<void> setSimulationMode(
    bool value,
  ) async {
    simulationMode = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _simulationKey,
      value,
    );

    if (!value) {
      connected = false;
      fallDetected = false;
      _stopInactivityMonitoring();
    }

    notifyListeners();
  }

  Future<void> setInactivityMonitoring(
    bool enabled,
  ) async {
    inactivityMonitoringEnabled = enabled;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _inactivityEnabledKey,
      enabled,
    );

    if (enabled) {
      lastActivityTime ??= DateTime.now();

      if (connected) {
        _startInactivityMonitoring();
      }
    } else {
      inactivityAlertActive = false;
      inactivitySosTriggered = false;

      _stopInactivityMonitoring();
    }

    notifyListeners();
  }

  Future<void> setInactivityLimitHours(
    int hours,
  ) async {
    if (![6, 12, 16, 24, 48]
        .contains(hours)) {
      return;
    }

    inactivityLimitHours = hours;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(
      _inactivityLimitHoursKey,
      hours,
    );

    if (connected &&
        inactivityMonitoringEnabled) {
      _startInactivityMonitoring();
    }

    notifyListeners();
  }

  Duration get inactivityLimit {
    return Duration(
      hours: inactivityLimitHours,
    );
  }

  String get inactivityLimitText {
    return '$inactivityLimitHours hours';
  }

  Future<void> setSleepSchedule({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    sleepStartHour = startHour;
    sleepStartMinute = startMinute;

    sleepEndHour = endHour;
    sleepEndMinute = endMinute;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(
      _sleepStartHourKey,
      startHour,
    );

    await prefs.setInt(
      _sleepStartMinuteKey,
      startMinute,
    );

    await prefs.setInt(
      _sleepEndHourKey,
      endHour,
    );

    await prefs.setInt(
      _sleepEndMinuteKey,
      endMinute,
    );

    notifyListeners();
  }

  String get sleepScheduleText {
    return '${_formatTime(
      sleepStartHour,
      sleepStartMinute,
    )} - ${_formatTime(
      sleepEndHour,
      sleepEndMinute,
    )}';
  }

  String _formatTime(
    int hour,
    int minute,
  ) {
    final suffix =
        hour >= 12 ? 'PM' : 'AM';

    final displayHour =
        hour % 12 == 0
            ? 12
            : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  bool get isWithinSleepSchedule {
    final now = DateTime.now();

    final currentMinutes =
        now.hour * 60 + now.minute;

    final startMinutes =
        sleepStartHour * 60 +
            sleepStartMinute;

    final endMinutes =
        sleepEndHour * 60 +
            sleepEndMinute;

    if (startMinutes == endMinutes) {
      return false;
    }

    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes ||
          currentMinutes < endMinutes;
    }

    return currentMinutes >= startMinutes &&
        currentMinutes < endMinutes;
  }

  void connectSimulation() {
    if (!simulationMode) {
      return;
    }

    connected = true;

    lastActivityTime ??= DateTime.now();

    if (inactivityMonitoringEnabled) {
      _startInactivityMonitoring();
    }

    notifyListeners();
  }

  void disconnectSimulation() {
    connected = false;

    _stopInactivityMonitoring();

    notifyListeners();
  }

  void _startInactivityMonitoring() {
    _inactivityTimer?.cancel();

    if (!connected ||
        !inactivityMonitoringEnabled) {
      return;
    }

    lastActivityTime ??= DateTime.now();

    _inactivityTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        _checkInactivity();
      },
    );

    _checkInactivity();
  }

  void _stopInactivityMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void markPhysicalActivity() {
    lastActivityTime =
        DateTime.now();

    inactivityAlertActive = false;
    inactivitySosTriggered = false;

    lastInactivityNotificationTime =
        null;

    notifyListeners();
  }

  void _checkInactivity() {
    if (!connected ||
        !inactivityMonitoringEnabled) {
      return;
    }

    final now = DateTime.now();

    lastActivityTime ??= now;

    if (isWithinSleepSchedule) {
      inactivityAlertActive = false;
      inactivitySosTriggered = false;

      notifyListeners();
      return;
    }

    final inactiveDuration =
        now.difference(
      lastActivityTime!,
    );

    if (inactiveDuration <
        inactivityLimit) {
      inactivityAlertActive = false;

      notifyListeners();
      return;
    }

    inactivityAlertActive = true;

    final shouldNotify =
        lastInactivityNotificationTime ==
                null ||
            now.difference(
                  lastInactivityNotificationTime!,
                ) >=
                const Duration(hours: 24);

    if (shouldNotify) {
      lastInactivityNotificationTime =
          now;

      inactivitySosTriggered = true;

      SafetyNotificationService.instance
          .notifyInactivity();
    }

    notifyListeners();
  }

  void simulateInactivityForDemo() {
    if (!connected ||
        !inactivityMonitoringEnabled) {
      return;
    }

    lastActivityTime =
        DateTime.now().subtract(
      inactivityLimit +
          const Duration(minutes: 1),
    );

    inactivityAlertActive = true;
    inactivitySosTriggered = true;

    lastInactivityNotificationTime =
        DateTime.now();

    SafetyNotificationService.instance
        .notifyInactivity();

    notifyListeners();
  }

  void clearInactivityAlert() {
    inactivityAlertActive = false;
    inactivitySosTriggered = false;

    lastInactivityNotificationTime =
        null;

    lastActivityTime =
        DateTime.now();

    notifyListeners();
  }

  void simulateFall() {
    if (!connected) {
      return;
    }

    fallDetected = true;

    if (!fallAlertActive) {
      fallAlertActive = true;

      SafetyNotificationService.instance
          .notifyFallDetected();
    }

    notifyListeners();
  }

  void clearFallAlert() {
    fallDetected = false;
    fallAlertActive = false;

    notifyListeners();
  }

  void updateSensorData({
    int? newHeartRate,
    int? newSpo2,
    int? newBattery,
    bool? newFallDetected,
  }) {
    if (!connected) {
      return;
    }

    if (newHeartRate != null) {
      heartRate = newHeartRate;

      final abnormal =
          heartRate < 50 ||
              heartRate > 120;

      if (abnormal &&
          !abnormalHeartRateAlertActive) {
        abnormalHeartRateAlertActive =
            true;

        SafetyNotificationService.instance
            .notifyAbnormalHeartRate(
          heartRate,
        );
      }

      if (!abnormal) {
        abnormalHeartRateAlertActive =
            false;
      }
    }

    if (newSpo2 != null) {
      spo2 = newSpo2;

      final abnormal =
          spo2 < 92;

      if (abnormal &&
          !lowSpo2AlertActive) {
        lowSpo2AlertActive = true;

        SafetyNotificationService.instance
            .notifyLowSpo2(
          spo2,
        );
      }

      if (!abnormal) {
        lowSpo2AlertActive = false;
      }
    }

    if (newBattery != null) {
      battery = newBattery;

      final lowBattery =
          battery <= 20;

      if (lowBattery &&
          !lowBatteryAlertActive) {
        lowBatteryAlertActive = true;

        SafetyNotificationService.instance
            .notifyLowBattery(
          battery,
        );
      }

      if (!lowBattery) {
        lowBatteryAlertActive = false;
      }
    }

    if (newFallDetected != null) {
      if (newFallDetected) {
        simulateFall();
      } else {
        clearFallAlert();
      }
    }

    notifyListeners();
  }

  void generateTestData() {
    if (!connected) {
      return;
    }

    final random =
        Random();

    heartRate =
        65 + random.nextInt(35);

    spo2 =
        95 + random.nextInt(5);

    battery =
        10 + random.nextInt(91);

    final fall =
        random.nextInt(10) == 0;

    if (fall) {
      simulateFall();
    } else {
      clearFallAlert();
    }

    markPhysicalActivity();

    notifyListeners();
  }

  void restoreNormalData() {
    if (!connected) {
      return;
    }

    updateSensorData(
      newHeartRate: 72,
      newSpo2: 98,
      newBattery: 100,
      newFallDetected: false,
    );

    clearFallAlert();
    clearInactivityAlert();

    notifyListeners();
  }

  Future<void> connectToDevice(
    BluetoothDevice selectedDevice,
  ) async {
    try {
      await selectedDevice.connect(
        license: License.nonprofit,
      );

      device = selectedDevice;
      connected = true;

      lastActivityTime ??= DateTime.now();

      if (inactivityMonitoringEnabled) {
        _startInactivityMonitoring();
      }

      notifyListeners();
    } catch (e) {
      connected = false;
      device = null;

      _stopInactivityMonitoring();

      notifyListeners();
    }
  }

  Future<void> disconnectBle() async {
    try {
      if (device != null) {
        await device!.disconnect();
      }
    } catch (e) {
      // Ignore disconnect errors.
    }

    device = null;
    connected = false;
    fallDetected = false;

    _stopInactivityMonitoring();

    notifyListeners();
  }

  @override
  void dispose() {
    _stopInactivityMonitoring();

    super.dispose();
  }
}