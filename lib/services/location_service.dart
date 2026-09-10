import 'dart:math';

import '../models/store.dart';
import 'geo_utils.dart';

/// Handles user location + radius-based store visibility.
///
/// Ab **real GPS** use hoti hai ([fetchCurrentLocation] browser/device se
/// location leta hai). Location milne tak / deny hone par [hasLocation] false
/// rehta hai aur koi store visible nahi hota (radius restriction sach me lagti
/// hai). Filtering logic (Haversine) same hai.
class LocationService {
  double? _lat;
  double? _lng;

  double? get currentLat => _lat;
  double? get currentLng => _lng;

  /// True jab tak real location fetch na ho jaye.
  bool get hasLocation => _lat != null && _lng != null;

  /// Real GPS location fetch karo. Success → true, deny/error → false.
  Future<bool> fetchCurrentLocation() async {
    final loc = await GeoUtils.getCurrentLocation();
    if (loc == null) return false;
    _lat = loc.latitude;
    _lng = loc.longitude;
    return true;
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
