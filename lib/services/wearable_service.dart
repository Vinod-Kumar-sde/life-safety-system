import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> loadSimulationMode() async {
    final prefs = await SharedPreferences.getInstance();

    simulationMode =
        prefs.getBool('simulation_mode') ?? true;

    if (!simulationMode) {
      connected = false;
      fallDetected = false;
    }

    notifyListeners();
  }

  Future<void> setSimulationMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'simulation_mode',
      value,
    );

    simulationMode = value;

    // Turning simulation OFF disconnects the simulated wearable.
    if (!value) {
      connected = false;
      fallDetected = false;
    }

    notifyListeners();
  }

  // --------------------------------------------------
  // SIMULATION
  // --------------------------------------------------

  void connectSimulation() {
    if (!simulationMode) {
      return;
    }

    connected = true;

    notifyListeners();
  }

  void disconnectSimulation() {
    connected = false;
    fallDetected = false;

    notifyListeners();
  }

  void generateTestData() {
    if (!simulationMode || !connected) {
      return;
    }

    final random = Random();

    heartRate = 65 + random.nextInt(35);
    spo2 = 95 + random.nextInt(5);
    battery = 10 + random.nextInt(91);

    fallDetected = random.nextInt(10) == 0;

    notifyListeners();
  }

  void simulateFall() {
    if (!simulationMode || !connected) {
      return;
    }

    fallDetected = true;

    notifyListeners();
  }

  void clearFallAlert() {
    fallDetected = false;

    notifyListeners();
  }

  // --------------------------------------------------
  // REAL BLE
  // --------------------------------------------------

  Future<void> connectToDevice(
    BluetoothDevice selectedDevice,
  ) async {
    try {
      await selectedDevice.connect( license: License.nonprofit,);

      device = selectedDevice;
      connected = true;

      notifyListeners();
    } catch (e) {
      connected = false;
      device = null;

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

    notifyListeners();
  }

  // --------------------------------------------------
  // SENSOR DATA
  // --------------------------------------------------

  void updateSensorData({
    int? newHeartRate,
    int? newSpo2,
    int? newBattery,
    bool? newFallDetected,
  }) {
    if (newHeartRate != null) {
      heartRate = newHeartRate;
    }

    if (newSpo2 != null) {
      spo2 = newSpo2;
    }

    if (newBattery != null) {
      battery = newBattery;
    }

    if (newFallDetected != null) {
      fallDetected = newFallDetected;
    }

    notifyListeners();
  }
}