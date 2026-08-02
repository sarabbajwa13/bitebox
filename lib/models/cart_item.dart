import 'menu_item.dart';

/// One line in the cart: a specific variant of an item + quantity.
class CartItem {
  final MenuItem item;
  final Variant variant;
  int quantity;

  CartItem({required this.item, required this.variant, this.quantity = 1});

  /// Unique key per (item + variant) so same item different variant stays separate.
  String get key => '${item.id}__${variant.id}';

  double get lineTotal => variant.price * quantity;

  Map<String, dynamic> toJson() => {
    'itemId': item.id,
    'itemName': item.name,
    'variantId': variant.id,
    'variantName': variant.name,
    'price': variant.price,
    'quantity': quantity,
  };
}
