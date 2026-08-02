import 'package:flutter/foundation.dart';

import '../data/repositories/data_repository.dart';
import '../models/store.dart';
import '../services/location_service.dart';

/// Loads stores and applies radius-based visibility filtering.
class StoreProvider extends ChangeNotifier {
  final DataRepository repository;
  final LocationService locationService;

  StoreProvider({required this.repository, required this.locationService});

  bool _loading = false;
  bool _hasLoaded = false;
  String? _error;
  List<Store> _allStores = [];
  List<Store> _visibleStores = [];

  bool get isLoading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  List<Store> get visibleStores => _visibleStores;

  /// True when exactly one store is visible in the user's radius.
  bool get hasSingleStore => _visibleStores.length == 1;
  Store? get singleStore => hasSingleStore ? _visibleStores.first : null;

  double distanceToStore(Store store) =>
      locationService.distanceToStore(store);

  Future<void> loadStores() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
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
}
