import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({
    super.key,
  });

  @override
  State<LocationScreen> createState() =>
      _LocationScreenState();
}

class _LocationScreenState
    extends State<LocationScreen> {
  Position? position;

  bool loading = true;
  bool locationAvailable = false;

  String statusMessage =
      'Checking location...';

  @override
  void initState() {
    super.initState();

    loadLocation();
  }

  Future<void> loadLocation() async {
    if (mounted) {
      setState(() {
        loading = true;
        statusMessage =
            'Getting your current location...';
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }

        setState(() {
          position = null;
          locationAvailable = false;
          loading = false;
          statusMessage =
              'Location services are turned off.';
        });

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }

        setState(() {
          position = null;
          locationAvailable = false;
          loading = false;
          statusMessage =
              'Location permission is permanently denied.';
        });

        return;
      }

      if (permission ==
          LocationPermission.denied) {
        if (!mounted) {
          return;
        }

        setState(() {
          position = null;
          locationAvailable = false;
          loading = false;
          statusMessage =
              'Location permission was denied.';
        });

        return;
      }

      final currentPosition =
          await LocationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      if (currentPosition == null) {
        setState(() {
          position = null;
          locationAvailable = false;
          loading = false;
          statusMessage =
              'Unable to get your current GPS location.';
        });

        return;
      }

      setState(() {
        position = currentPosition;
        locationAvailable = true;
        loading = false;
        statusMessage =
            'Location updated successfully.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        position = null;
        locationAvailable = false;
        loading = false;
        statusMessage =
            'Unable to access GPS location.';
      });
    }
  }

  Future<void> openLocationInMaps() async {
    final currentPosition = position;

    if (currentPosition == null) {
      return;
    }

    final latitude = currentPosition.latitude;
    final longitude = currentPosition.longitude;

    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$latitude,$longitude',
    );

    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude',
    );

    try {
      // First try the Google Maps web URL directly.
      // Do not use canLaunchUrl() because Android can
      // report false even when a suitable app/browser exists.
      final launchedGoogleMaps = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (launchedGoogleMaps) {
        return;
      }

      // Fallback to Android geo URI.
      final launchedGeo = await launchUrl(
        geoUri,
        mode: LaunchMode.externalApplication,
      );

      if (launchedGeo) {
        return;
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Google Maps or another map application.',
          ),
        ),
      );
    } catch (e) {
      try {
        final launchedGeo = await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );

        if (launchedGeo) {
          return;
        }
      } catch (_) {}

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the map.',
          ),
        ),
      );
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open location settings.',
          ),
        ),
      );
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open app settings.',
          ),
        ),
      );
    }
  }

  String formatCoordinate(
    double value,
  ) {
    return value.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = position;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current Location',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadLocation,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          children: [
            _buildStatusCard(),

            const SizedBox(
              height: 16,
            ),

            if (currentPosition != null)
              _buildCoordinatesCard(
                currentPosition,
              ),

            if (currentPosition != null)
              const SizedBox(
                height: 16,
              ),

            _buildActionsCard(),

            const SizedBox(
              height: 16,
            ),

            _buildInformationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = loading
        ? Colors.orange
        : locationAvailable
            ? Colors.green
            : Colors.red;

    final icon = loading
        ? Icons.gps_not_fixed
        : locationAvailable
            ? Icons.gps_fixed
            : Icons.gps_off;

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        gradient: LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            color.withOpacity(0.14),
            color.withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color:
              color.withOpacity(0.20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
                BoxDecoration(
              color:
                  color.withOpacity(0.12),
              shape:
                  BoxShape.circle,
            ),
            child: loading
                ? const Padding(
                    padding:
                        EdgeInsets.all(18),
                    child:
                        CircularProgressIndicator(),
                  )
                : Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            loading
                ? 'Getting Location'
                : locationAvailable
                    ? 'Location Available'
                    : 'Location Unavailable',
            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            statusMessage,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatesCard(
    Position currentPosition,
  ) {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  'GPS Coordinates',
                  style:
                      TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            _coordinateRow(
              'Latitude',
              formatCoordinate(
                currentPosition.latitude,
              ),
            ),

            const Divider(
              height: 22,
            ),

            _coordinateRow(
              'Longitude',
              formatCoordinate(
                currentPosition.longitude,
              ),
            ),

            const Divider(
              height: 22,
            ),

            _coordinateRow(
              'Accuracy',
              '${currentPosition.accuracy.toStringAsFixed(1)} m',
            ),

            if (currentPosition.altitude !=
                0) ...[
              const Divider(
                height: 22,
              ),
              _coordinateRow(
                'Altitude',
                '${currentPosition.altitude.toStringAsFixed(1)} m',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _coordinateRow(
    String label,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    loading
                        ? null
                        : loadLocation,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Refresh Location',
                ),
              ),
            ),

            if (locationAvailable) ...[
              const SizedBox(
                height: 10,
              ),

              SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      openLocationInMaps,
                  icon: const Icon(
                    Icons.map,
                  ),
                  label: const Text(
                    'Open in Google Maps',
                  ),
                ),
              ),
            ],

            if (!locationAvailable &&
                !loading) ...[
              const SizedBox(
                height: 10,
              ),

              if (statusMessage.contains(
                'turned off',
              ))
                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        openLocationSettings,
                    icon: const Icon(
                      Icons.settings,
                    ),
                    label: const Text(
                      'Open Location Settings',
                    ),
                  ),
                ),

              if (statusMessage.contains(
                'permission',
              ))
                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        openAppSettings,
                    icon: const Icon(
                      Icons.settings,
                    ),
                    label: const Text(
                      'Open App Settings',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Colors.blue.withOpacity(
          0.06,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.blue.withOpacity(
            0.12,
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                'Location Safety',
                style:
                    TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Your current GPS location can be used during an SOS emergency and for Safe Zone monitoring.',
            style:
                TextStyle(
              height: 1.5,
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'For best accuracy, keep GPS/location services enabled.',
            style:
                TextStyle(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}