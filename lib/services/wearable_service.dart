import 'dart:math';

class WearableService {
  static bool connected = false;

  static int heartRate = 72;
  static int spo2 = 98;
  static int battery = 100;
  static bool fallDetected = false;

  static void connectSimulation() {
    connected = true;
  }

  static void disconnectSimulation() {
    connected = false;
  }

  static void generateTestData() {
    final random = Random();

    heartRate = 65 + random.nextInt(35);
    spo2 = 95 + random.nextInt(5);
    battery = 10 + random.nextInt(91);
    fallDetected = random.nextInt(10) == 0;
  }
}