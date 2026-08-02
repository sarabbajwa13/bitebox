import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';

/// Shopping cart state. Cart ek hi store ka hota hai — naya store choose
/// karne pe cart clear ho jaata hai (simple, quick-order flow).
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _storeId;
  String? _storeName;

  List<CartItem> get items => _items.values.toList();
  String? get storeId => _storeId;
  String? get storeName => _storeName;

  bool get isEmpty => _items.isEmpty;
  int get totalQuantity =>
      _items.values.fold(0, (sum, e) => sum + e.quantity);
  double get subtotal =>
      _items.values.fold(0.0, (sum, e) => sum + e.lineTotal);

  int quantityOf(String itemId, String variantId) {
    final key = '${itemId}__$variantId';
    return _items[key]?.quantity ?? 0;
  }

  void _ensureStore(MenuItem item, String storeName) {
    if (_storeId != null && _storeId != item.storeId) {
      _items.clear(); // different store → reset cart
    }
    _storeId = item.storeId;
    _storeName = storeName;
  }

  void add(MenuItem item, Variant variant, String storeName) {
    _ensureStore(item, storeName);
    final key = '${item.id}__${variant.id}';
    final existing = _items[key];
    if (existing != null) {
      existing.quantity++;
    } else {
      _items[key] = CartItem(item: item, variant: variant);
    }
    notifyListeners();
  }

  void decrement(MenuItem item, Variant variant) {
    final key = '${item.id}__${variant.id}';
    final existing = _items[key];
    if (existing == null) return;
    if (existing.quantity > 1) {
      existing.quantity--;
    } else {
      _items.remove(key);
    }
    if (_items.isEmpty) {
      _storeId = null;
      _storeName = null;
    }
    notifyListeners();
  }

  void removeLine(CartItem line) {
    _items.remove(line.key);
    if (_items.isEmpty) {
      _storeId = null;
      _storeName = null;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _storeId = null;
    _storeName = null;
    notifyListeners();
  }
}
