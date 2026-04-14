import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dio_client.dart';

class LocationService {
  /// Gets GPS permission and current position.
  /// Returns null if permission denied — never crashes.
  Future<Position?> getLocationPermissionAndPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  /// Sends coordinates to backend silently — never blocks UI.
  Future<void> updateLocationOnBackend(double lat, double lng) async {
    try {
      await DioClient.instance.patch(
        '/donors/me/location',
        data: {'latitude': lat, 'longitude': lng},
      );
      debugPrint('Location updated: $lat, $lng');
    } catch (e) {
      // Non-critical — donor profile still works without location
      debugPrint('Location update failed (non-critical): $e');
    }
  }
}