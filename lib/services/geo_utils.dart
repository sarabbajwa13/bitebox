import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Delivery location helpers — current location fetch + radius clamping.
class GeoUtils {
  GeoUtils._();

  static const Distance _distance = Distance();

  /// Last location-fetch error (diagnostic — UI isse dikha sakta hai).
  static String? lastError;

  /// Customer ki current location (browser/GPS). Permission deny / error →
  /// null (caller store location pe fallback kar sakta hai).
  ///
  /// **Web:** browser ka permission prompt `getCurrentPosition()` pe hi aata
  /// hai — isliye web pe check/request dance skip karke seedha position lete
  /// hain (warna prompt kabhi nahi aata). **Mobile:** normal permission flow.
  static Future<LatLng?> getCurrentLocation() async {
    lastError = null;
    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          lastError = 'Location services are off';
          return null;
        }
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          lastError = 'Permission: $perm';
          return null;
        }
      }
      // Web: yahi call browser prompt trigger karti hai.
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  /// Distance in km between two points.
  static double distanceKm(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Kilometer, a, b);

  /// Kya point store ke radius ke andar hai?
  static bool withinRadius(LatLng store, LatLng point, double radiusKm) =>
      distanceKm(store, point) <= radiusKm;

  /// Point ko store ke radius ke andar clamp karo — agar bahar ho to boundary
  /// pe (store se point ke direction me) le aao.
  static LatLng clampToRadius(LatLng store, LatLng point, double radiusKm) {
    final meters = _distance.as(LengthUnit.Meter, store, point);
    final radiusMeters = radiusKm * 1000;
    if (meters <= radiusMeters) return point;
    final bearing = _distance.bearing(store, point);
    return _distance.offset(store, radiusMeters, bearing);
  }
}
