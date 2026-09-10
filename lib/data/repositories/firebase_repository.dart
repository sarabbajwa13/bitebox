import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_config.dart';
import '../../models/store.dart';
import '../../models/menu_item.dart';
import '../../models/order.dart';
import 'data_repository.dart';

/// Firestore-backed data layer. Agent app isi `stores`/`products` ko manage
/// karta hai aur `orders` yahan se receive karta hai.
class FirebaseRepository implements DataRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<List<Store>> getStores() async {
    final snap = await _db.collection(AppConfig.storesCollection).get();
    return snap.docs.map((d) => Store.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<MenuItem>> getMenuForStore(String storeId) async {
    final snap = await _db
        .collection(AppConfig.productsCollection)
        .where('storeId', isEqualTo: storeId)
        .get();
    return snap.docs
        // Sirf available products dikhao (agent isAvailable off kar sakta hai).
        .where((d) => (d.data()['isAvailable'] ?? true) == true)
        .map((d) => MenuItem.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<CustomerOrder> placeOrder(CustomerOrder order) async {
    // Firestore auto-generated doc id — globally unique, kabhi overwrite nahi.
    final ref = _db.collection(AppConfig.ordersCollection).doc();
    await ref.set(order.toMap());
    // Real doc id ke saath order wapas (navigation/tracking isi id pe).
    return CustomerOrder.fromMap(ref.id, order.toMap());
  }

  @override
  Stream<List<CustomerOrder>> watchOrders(String customerId) {
    return _db
        .collection(AppConfig.ordersCollection)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => CustomerOrder.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
