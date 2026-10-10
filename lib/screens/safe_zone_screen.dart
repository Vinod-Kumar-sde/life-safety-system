import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/safety_notification_service.dart';
import 'sos_screen.dart';

class SafeZoneScreen extends StatefulWidget {
  const SafeZoneScreen({super.key});

  @override
  State<SafeZoneScreen> createState() =>
      _SafeZoneScreenState();
}

class _SafeZoneScreenState
    extends State<SafeZoneScreen> {
  double? safeLatitude;
  double? safeLongitude;

  // Allowed Safe Zone radius values.
  static const List<double> radiusOptions = [
    500,
    1000,
    2000,
  ];

  double radius = 500;

  Position? currentPosition;

  bool loading = false;
  bool monitoring = false;

  bool automaticSosTriggered = false;

  Timer? monitoringTimer;

  @override
  void initState() {
    super.initState();

    loadSafeZone();
  }

  @override
  void dispose() {
    monitoringTimer?.cancel();

    super.dispose();
  }

  // --------------------------------------------------
  // LOAD SAFE ZONE
  // --------------------------------------------------

  Future<void> loadSafeZone() async {
    final prefs =
        await SharedPreferences.getInstance();

    final latitude =
        prefs.getDouble(
      'safe_zone_latitude',
    );

    final longitude =
        prefs.getDouble(
      'safe_zone_longitude',
    );

    final savedRadius =
        prefs.getDouble(
      'safe_zone_radius',
    );

    // If an old/invalid radius exists,
    // automatically use 500 meters.
    double validRadius = 500;

    if (savedRadius != null &&
        radiusOptions.contains(savedRadius)) {
      validRadius = savedRadius;
    }

    // Fix old invalid value in storage too.
    if (savedRadius != validRadius) {
      await prefs.setDouble(
        'safe_zone_radius',
        validRadius,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      safeLatitude = latitude;
      safeLongitude = longitude;
      radius = validRadius;

      monitoring =
          latitude != null &&
              longitude != null;
    });

    if (monitoring) {
      _startMonitoring();
    }
  }

  // --------------------------------------------------
  // SET SAFE ZONE
  // --------------------------------------------------

  Future<void> setSafeZone() async {
    setState(() {
      loading = true;
    });

    final position =
        await LocationService
            .getCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });

    if (position == null) {
      showMessage(
        'Unable to get your location. Please enable GPS and location permission.',
      );

      return;
    }

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setDouble(
      'safe_zone_latitude',
      position.latitude,
    );

    await prefs.setDouble(
      'safe_zone_longitude',
      position.longitude,
    );

    await prefs.setDouble(
      'safe_zone_radius',
      radius,
    );

    automaticSosTriggered = false;

    setState(() {
      safeLatitude =
          position.latitude;

      safeLongitude =
          position.longitude;

      currentPosition =
          position;

      monitoring = true;
    });

    _startMonitoring();

    showMessage(
      'Safe Zone saved successfully. Automatic monitoring started.',
    );
  }

  // --------------------------------------------------
  // START MONITORING
  // --------------------------------------------------

  void _startMonitoring() {
    monitoringTimer?.cancel();

    if (safeLatitude == null ||
        safeLongitude == null) {
      return;
    }

    monitoring = true;

    // Check immediately.
    _checkSafeZone();

    // Continue checking every 15 seconds.
    monitoringTimer =
        Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _checkSafeZone();
      },
    );
  }

  // --------------------------------------------------
  // CHECK SAFE ZONE
  // --------------------------------------------------

  Future<void> _checkSafeZone() async {
    if (!monitoring ||
        safeLatitude == null ||
        safeLongitude == null) {
      return;
    }

    final position =
        await LocationService
            .getCurrentLocation();

    if (!mounted ||
        position == null) {
      return;
    }

    setState(() {
      currentPosition = position;
    });

    final distance =
        getDistanceFromSafeZone();

    if (distance == null) {
      return;
    }

    final outside =
        distance > radius;

    // Person is inside the Safe Zone.
    if (!outside) {
      // Reset the trigger so a future exit
      // can generate another SOS.
      automaticSosTriggered = false;

      return;
    }

    // Person is outside.
    //
    // Prevent repeatedly opening SOS every
    // 15 seconds while still outside.
    if (automaticSosTriggered) {
      return;
    }

    automaticSosTriggered = true;

    // First record the Safe Zone alert.
    await SafetyNotificationService
        .instance
        .notifySafeZoneExit(
      distance,
      radius,
    );

    if (!mounted) {
      return;
    }

    // --------------------------------------------------
    // AUTOMATIC SOS
    // --------------------------------------------------
    //
    // autoSend = true means SOSScreen will
    // immediately send the SMS.
    //
    // There is NO countdown here.
    // --------------------------------------------------

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SOSScreen(
          autoSend: true,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MANUAL LOCATION CHECK
  // --------------------------------------------------

  Future<void> refreshLocation() async {
    setState(() {
      loading = true;
    });

    final position =
        await LocationService
            .getCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
      currentPosition = position;
    });

    if (position == null) {
      showMessage(
        'Unable to get current location.',
      );

      return;
    }

    await _checkSafeZone();
  }

  // --------------------------------------------------
  // CLEAR SAFE ZONE
  // --------------------------------------------------

  Future<void> clearSafeZone() async {
    monitoringTimer?.cancel();

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      'safe_zone_latitude',
    );

    await prefs.remove(
      'safe_zone_longitude',
    );

    await prefs.remove(
      'safe_zone_radius',
    );

    setState(() {
      safeLatitude = null;
      safeLongitude = null;
      currentPosition = null;
      monitoring = false;
      automaticSosTriggered = false;
      radius = 500;
    });

    showMessage(
      'Safe Zone removed.',
    );
  }

  // --------------------------------------------------
  // DISTANCE
  // --------------------------------------------------

  double? getDistanceFromSafeZone() {
    if (safeLatitude == null ||
        safeLongitude == null ||
        currentPosition == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      safeLatitude!,
      safeLongitude!,
      currentPosition!.latitude,
      currentPosition!.longitude,
    );
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final distance =
        getDistanceFromSafeZone();

    final insideZone =
        distance != null &&
            distance <= radius;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Safe Zone'),
        backgroundColor:
            Colors.pink,
        foregroundColor:
            Colors.white,
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Card(
              color:
                  Colors.pink.shade50,
              child: const Padding(
                padding:
                    EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color:
                          Colors.pink,
                      size: 40,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Safe Zone',
                            style:
                                TextStyle(
                              fontSize:
                                  22,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Leave the trusted area and an SOS is sent automatically.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // --------------------------------------------------
            // STATUS
            // --------------------------------------------------

            Card(
              elevation: 3,
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  children: [
                    Icon(
                      safeLatitude == null
                          ? Icons
                              .shield_outlined
                          : distance == null
                              ? Icons
                                  .location_searching
                              : insideZone
                                  ? Icons
                                      .check_circle
                                  : Icons
                                      .warning,
                      size: 65,
                      color:
                          safeLatitude ==
                                  null
                              ? Colors.grey
                              : distance == null
                                  ? Colors
                                      .orange
                                  : insideZone
                                      ? Colors
                                          .green
                                      : Colors
                                          .red,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      safeLatitude == null
                          ? 'Safe Zone Not Set'
                          : distance == null
                              ? 'Location Not Checked'
                              : insideZone
                                  ? 'Inside Safe Zone'
                                  : 'OUTSIDE SAFE ZONE',
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    if (distance != null)
                      Text(
                        'Distance: ${distance.toStringAsFixed(0)} m',
                        style:
                            const TextStyle(
                          fontSize: 16,
                        ),
                      ),

                    const SizedBox(
                      height: 8,
                    ),

                    if (monitoring)
                      const Text(
                        'Automatic monitoring: ON',
                        style:
                            TextStyle(
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // --------------------------------------------------
            // RADIUS
            // --------------------------------------------------

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'Safe Zone Radius',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    DropdownButtonFormField<
                        double>(
                      // This can NEVER receive
                      // an invalid old value.
                      initialValue:
                          radiusOptions
                                  .contains(
                        radius,
                      )
                              ? radius
                              : 500,

                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(
                          Icons
                              .radio_button_checked,
                        ),
                      ),

                      items:
                          radiusOptions
                              .map(
                        (value) {
                          final label =
                              value < 1000
                                  ? '${value.toInt()} meters'
                                  : '${(value / 1000).toStringAsFixed(0)} kilometer';

                          return DropdownMenuItem<
                              double>(
                            value: value,
                            child:
                                Text(label),
                          );
                        },
                      ).toList(),

                      onChanged:
                          (value) async {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          radius =
                              value;
                        });

                        // Save the new radius
                        // immediately.
                        final prefs =
                            await SharedPreferences
                                .getInstance();

                        await prefs
                            .setDouble(
                          'safe_zone_radius',
                          value,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // --------------------------------------------------
            // SET SAFE ZONE
            // --------------------------------------------------

            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  ElevatedButton.icon(
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      Colors.pink,
                  foregroundColor:
                      Colors.white,
                ),
                onPressed:
                    loading
                        ? null
                        : setSafeZone,
                icon: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .location_on,
                      ),
                label: Text(
                  safeLatitude == null
                      ? 'Set Current Location as Safe Zone'
                      : 'Update Safe Zone Location',
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // --------------------------------------------------
            // REFRESH
            // --------------------------------------------------

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  OutlinedButton.icon(
                onPressed:
                    loading
                        ? null
                        : refreshLocation,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Check Current Location',
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // --------------------------------------------------
            // CLEAR
            // --------------------------------------------------

            if (safeLatitude != null)
              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    OutlinedButton.icon(
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        Colors.red,
                  ),
                  onPressed:
                      clearSafeZone,
                  icon: const Icon(
                    Icons
                        .delete_outline,
                  ),
                  label: const Text(
                    'Remove Safe Zone',
                  ),
                ),
              ),

            const SizedBox(
              height: 20,
            ),

            // --------------------------------------------------
            // LOCATION DETAILS
            // --------------------------------------------------

            if (safeLatitude != null)
              Card(
                child: ListTile(
                  leading:
                      const Icon(
                    Icons.location_on,
                    color:
                        Colors.pink,
                  ),
                  title:
                      const Text(
                    'Safe Zone Location',
                  ),
                  subtitle:
                      Text(
                    '${safeLatitude!.toStringAsFixed(6)}, '
                    '${safeLongitude!.toStringAsFixed(6)}\n'
                    'Radius: ${radius.toStringAsFixed(0)} meters',
                  ),
                ),
              ),

            const SizedBox(
              height: 15,
            ),

            // --------------------------------------------------
            // AUTOMATIC SOS INFORMATION
            // --------------------------------------------------

            if (monitoring)
              Card(
                color:
                    Colors.red.shade50,
                child: const Padding(
                  padding:
                      EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons.warning,
                        color:
                            Colors.red,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'If the person leaves this Safe Zone, the app automatically sends an SOS SMS to the emergency contacts.',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}