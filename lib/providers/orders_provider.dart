import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/data_repository.dart';
import '../models/order.dart';

/// Customer ke apne orders — Firestore se **real-time** (status agent ke
/// update pe live badalta hai). Koi simulation nahi.
class OrdersProvider extends ChangeNotifier {
  final DataRepository repository;
  OrdersProvider({required this.repository});

  StreamSubscription<List<CustomerOrder>>? _sub;
  String? _customerId;
  bool _loading = false;
  List<CustomerOrder> _orders = [];

  bool get isLoading => _loading;
  List<CustomerOrder> get orders => List.unmodifiable(_orders);
  bool get hasOrders => _orders.isNotEmpty;

  CustomerOrder? byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Logged-in customer ke orders sunna shuru karo (idempotent).
  void start(String customerId) {
    if (_customerId == customerId && _sub != null) return;
    _customerId = customerId;
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = repository.watchOrders(customerId).listen((list) {
      _orders = list;
      _loading = false;
      notifyListeners();
    }, onError: (_) {
      _loading = false;
      notifyListeners();
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _customerId = null;
    _orders = [];
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
