import 'dart:math';

import '../config/app_config.dart';
import '../models/store.dart';

/// Handles user location + radius-based store visibility.
///
/// Abhi configured location use hoti hai ([AppConfig.userLat/Lng]). Real GPS
/// chahiye to sirf [currentLat]/[currentLng] ko geolocator se bhar dena —
/// baaki filtering logic same rahega.
class LocationService {
  double get currentLat => AppConfig.userLat;
  double get currentLng => AppConfig.userLng;

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

  /// Distance of a store from the current user (km).
  double distanceToStore(Store store) =>
      distanceKm(currentLat, currentLng, store.lat, store.lng);

  /// A store is visible if the user is within the store's own radius.
  bool isStoreVisible(Store store) =>
      distanceToStore(store) <= store.radiusKm;

  /// Filter + sort stores by nearest first, keeping only in-range ones.
  List<Store> visibleStoresSortedByDistance(List<Store> stores) {
    final visible = stores.where(isStoreVisible).toList();
    visible.sort(
      (a, b) => distanceToStore(a).compareTo(distanceToStore(b)),
    );
    return visible;
  }
}
