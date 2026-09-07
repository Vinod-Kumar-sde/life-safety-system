import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

class SafeZoneScreen extends StatefulWidget {
  const SafeZoneScreen({super.key});

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  double? safeLatitude;
  double? safeLongitude;
  double radius = 500;

  Position? currentPosition;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadSafeZone();
  }

  Future<void> loadSafeZone() async {
    final prefs = await SharedPreferences.getInstance();

    final latitude = prefs.getDouble('safe_zone_latitude');
    final longitude = prefs.getDouble('safe_zone_longitude');
    final savedRadius =
        prefs.getDouble('safe_zone_radius');

    if (!mounted) return;

    setState(() {
      safeLatitude = latitude;
      safeLongitude = longitude;

      if (savedRadius != null) {
        radius = savedRadius;
      }
    });
  }

  Future<void> setSafeZone() async {
    setState(() {
      loading = true;
    });

    final position =
        await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (position == null) {
      showMessage(
        'Unable to get your location. Please enable GPS and location permission.',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

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

    setState(() {
      safeLatitude = position.latitude;
      safeLongitude = position.longitude;
      currentPosition = position;
    });

    showMessage('Safe Zone saved successfully.');
  }

  Future<void> refreshLocation() async {
    setState(() {
      loading = true;
    });

    final position =
        await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      loading = false;
      currentPosition = position;
    });

    if (position == null) {
      showMessage(
        'Unable to get current location.',
      );
    }
  }

  Future<void> clearSafeZone() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('safe_zone_latitude');
    await prefs.remove('safe_zone_longitude');
    await prefs.remove('safe_zone_radius');

    setState(() {
      safeLatitude = null;
      safeLongitude = null;
      currentPosition = null;
    });

    showMessage('Safe Zone removed.');
  }

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = getDistanceFromSafeZone();

    final insideZone =
        distance != null && distance <= radius;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Zone'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.pink.shade50,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color: Colors.pink,
                      size: 40,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe Zone',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Set a trusted location and monitor whether you are inside it.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Current status
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      safeLatitude == null
                          ? Icons.shield_outlined
                          : insideZone
                              ? Icons.check_circle
                              : Icons.warning,
                      size: 65,
                      color: safeLatitude == null
                          ? Colors.grey
                          : insideZone
                              ? Colors.green
                              : Colors.red,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      safeLatitude == null
                          ? 'Safe Zone Not Set'
                          : distance == null
                              ? 'Location Not Checked'
                              : insideZone
                                  ? 'Inside Safe Zone'
                                  : 'Outside Safe Zone',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (distance != null)
                      Text(
                        'Distance: ${distance.toStringAsFixed(0)} m',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Radius
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safe Zone Radius',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    DropdownButtonFormField<double>(
                      initialValue: radius,
                      decoration:
                          const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.radio_button_checked),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 500,
                          child: Text('500 meters'),
                        ),
                        DropdownMenuItem(
                          value: 1000,
                          child: Text('1 kilometer'),
                        ),
                        DropdownMenuItem(
                          value: 2000,
                          child: Text('2 kilometers'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            radius = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Set Safe Zone
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                onPressed: loading
                    ? null
                    : setSafeZone,
                icon: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.location_on),
                label: Text(
                  safeLatitude == null
                      ? 'Set Current Location as Safe Zone'
                      : 'Update Safe Zone Location',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Refresh
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed:
                    loading ? null : refreshLocation,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Check Current Location',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Clear
            if (safeLatitude != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: clearSafeZone,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    'Remove Safe Zone',
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (safeLatitude != null)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Colors.pink,
                  ),
                  title: const Text(
                    'Safe Zone Location',
                  ),
                  subtitle: Text(
                    '${safeLatitude!.toStringAsFixed(6)}, '
                    '${safeLongitude!.toStringAsFixed(6)}\n'
                    'Radius: ${radius.toStringAsFixed(0)} meters',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}