import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check whether phone location is turned on
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      // Check location permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      // Ask for permission if not granted
      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      // Permission permanently denied
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Permission denied
      if (permission == LocationPermission.denied) {
        return null;
      }

      // Get current GPS location
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      // Prevent the app from crashing if GPS fails
      return null;
    }
  }
}