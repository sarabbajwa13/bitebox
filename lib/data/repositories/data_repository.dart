import '../../models/store.dart';
import '../../models/menu_item.dart';
import '../../models/order.dart';

/// Abstract data layer. UI sirf isi interface se baat karti hai.
/// [FirebaseRepository] Firestore pe implement karti hai.
abstract class DataRepository {
  Future<List<Store>> getStores();
  Future<List<MenuItem>> getMenuForStore(String storeId);

  /// Order create karke Firestore me likho (id ke saath wapas).
  Future<CustomerOrder> placeOrder(CustomerOrder order);

  /// Customer ke apne orders ka real-time stream (order history + tracking).
  Stream<List<CustomerOrder>> watchOrders(String customerId);
}
