import 'package:flutter/foundation.dart';

import '../data/repositories/data_repository.dart';
import '../models/store.dart';
import '../services/geo_utils.dart';
import '../services/location_service.dart';

/// Loads stores and applies radius-based visibility filtering.
class StoreProvider extends ChangeNotifier {
  final DataRepository repository;
  final LocationService locationService;

  StoreProvider({required this.repository, required this.locationService});

  bool _loading = false;
  bool _hasLoaded = false;
  bool _locationDenied = false;
  String? _error;
  List<Store> _allStores = [];
  List<Store> _visibleStores = [];

  bool get isLoading => _loading;
  bool get hasLoaded => _hasLoaded;

  /// True jab location permission deny/unavailable ho (store list khaali).
  bool get locationDenied => _locationDenied;

  /// Diagnostic — location fetch kyun fail hui.
  String? locationError;
  String? get error => _error;
  List<Store> get visibleStores => _visibleStores;

  /// True when exactly one store is visible in the user's radius.
  bool get hasSingleStore => _visibleStores.length == 1;
  Store? get singleStore => hasSingleStore ? _visibleStores.first : null;

  /// Store by id (delivery location picker ko store lat/lng/radius chahiye).
  Store? byId(String id) {
    for (final s in _allStores) {
      if (s.id == id) return s;
    }
    return null;
  }

  double distanceToStore(Store store) =>
      locationService.distanceToStore(store);

  Future<void> loadStores() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Real GPS fetch — isi ke radius ke andar wale stores hi dikhenge.
      final gotLocation = await locationService.fetchCurrentLocation();
      _locationDenied = !gotLocation;
      locationError = gotLocation ? null : GeoUtils.lastError;
      _allStores = await repository.getStores();
      _visibleStores =
          locationService.visibleStoresSortedByDistance(_allStores);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  /// Pull-to-refresh / retry — location dubara fetch karke reload.
  Future<void> reload() async {
    _hasLoaded = false;
    await loadStores();
  }
}
