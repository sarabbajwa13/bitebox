import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/store.dart';
import 'geo_utils.dart';

/// Handles user location + radius-based store visibility.
///
/// Ab **real GPS** use hoti hai ([fetchCurrentLocation] browser/device se
/// location leta hai). Ek baar mili location localStorage me **cache** hoti hai
/// ([loadCachedLocation]) — taaki har refresh pe dobara GPS prompt na aaye.
/// Location deny hone par [hasLocation] false rehta hai aur koi store visible
/// nahi hota. Filtering logic (Haversine) same hai.
class LocationService {
  static const String _kLat = 'loc_lat';
  static const String _kLng = 'loc_lng';

  double? _lat;
  double? _lng;

  double? get currentLat => _lat;
  double? get currentLng => _lng;

  /// True jab location maujood ho (cached ya fresh).
  bool get hasLocation => _lat != null && _lng != null;

  /// Pehle cache ki gayi location load karo (koi GPS prompt nahi). Mili → true.
  Future<bool> loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final la = prefs.getDouble(_kLat);
      final ln = prefs.getDouble(_kLng);
      if (la != null && ln != null) {
        _lat = la;
        _lng = ln;
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Real GPS location fetch karo (prompt aa sakta hai). Success pe cache bhi.
  Future<bool> fetchCurrentLocation() async {
    final loc = await GeoUtils.getCurrentLocation();
    if (loc == null) return false;
    _lat = loc.latitude;
    _lng = loc.longitude;
    _cache();
    return true;
  }

  Future<void> _cache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLat, _lat!);
      await prefs.setDouble(_kLng, _lng!);
    } catch (_) {}
  }

  /// Great-circle distance (km) between two lat/lng points (Haversine).
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;

  /// Distance of a store from the current user (km). Location na ho to
  /// infinity (store visible nahi hoga).
  double distanceToStore(Store store) {
    if (!hasLocation) return double.infinity;
    return distanceKm(_lat!, _lng!, store.lat, store.lng);
  }

  /// A store is visible if the user is within the store's own radius.
  bool isStoreVisible(Store store) =>
      distanceToStore(store) <= store.radiusKm;

  /// Filter + sort stores by nearest first, keeping only in-range ones.
  /// Location na ho to empty (kuch bhi nahi dikhega).
  List<Store> visibleStoresSortedByDistance(List<Store> stores) {
    if (!hasLocation) return const [];
    final visible = stores.where(isStoreVisible).toList();
    visible.sort(
      (a, b) => distanceToStore(a).compareTo(distanceToStore(b)),
    );
    return visible;
  }
}
