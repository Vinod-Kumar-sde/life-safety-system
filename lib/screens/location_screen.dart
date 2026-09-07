import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String locationText = 'Location not loaded';
  double? latitude;
  double? longitude;
  bool loading = false;

  Future<void> getLocation() async {
    setState(() {
      loading = true;
      locationText = 'Getting location...';
    });

    final position = await LocationService.getCurrentLocation();

    if (position == null) {
      setState(() {
        loading = false;
        locationText = 'Unable to get location';
      });
      return;
    }

    setState(() {
      loading = false;
      latitude = position.latitude;
      longitude = position.longitude;
      locationText = 'Location available';
    });
  }

  Future<void> openMaps() async {
    if (latitude == null || longitude == null) {
      return;
    }

    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open Google Maps.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.location_on,
              size: 80,
            ),

            const SizedBox(height: 15),

            Text(
              locationText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Latitude'),
                trailing: Text(
                  latitude == null
                      ? '--'
                      : latitude!.toStringAsFixed(6),
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Longitude'),
                trailing: Text(
                  longitude == null
                      ? '--'
                      : longitude!.toStringAsFixed(6),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : getLocation,
                icon: const Icon(Icons.my_location),
                label: Text(
                  loading
                      ? 'Getting Location...'
                      : 'Refresh Location',
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: latitude == null ? null : openMaps,
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}