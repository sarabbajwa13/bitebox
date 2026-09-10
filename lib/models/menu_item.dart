/// A single selectable option of a menu item (e.g. "Cheese" vs "Potato Cheese").
class Variant {
  final String id;
  final String name;
  final double price;

  const Variant({required this.id, required this.name, required this.price});

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}

/// A menu item belonging to a store. Has 1+ variants.
class MenuItem {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final bool isVeg;

  /// Base price — bina variant ke item isi price pe bikta hai.
  final double price;
  final List<Variant> variants;

  const MenuItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.isVeg,
    required this.price,
    required this.variants,
  });

  /// Cart/order me daalne yogya variants. Agar agent ne koi variant nahi diya
  /// to ek default variant banate hain (item ke naam + base price se) — taaki
  /// baaki flow (cart, order) same rahe aur customer ko item ka naam dikhe.
  List<Variant> get sellableVariants => variants.isNotEmpty
      ? variants
      : [Variant(id: 'default', name: name, price: price)];

  /// Lowest sellable price — used for "from ₹X" display.
  double get startingPrice =>
      sellableVariants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  bool get hasMultipleVariants => sellableVariants.length > 1;

  /// Firestore `products` document → MenuItem.
  factory MenuItem.fromMap(String id, Map<String, dynamic> json) {
    final variants = ((json['variants'] as List<dynamic>?) ?? [])
        .map((v) => Variant.fromJson(v as Map<String, dynamic>))
        .toList();
    // Backward-compat: purane products me base price nahi tha.
    final basePrice = (json['price'] as num?)?.toDouble() ??
        (variants.isNotEmpty ? variants.first.price : 0);
    return MenuItem(
      id: id,
      storeId: (json['storeId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      category: (json['category'] ?? 'Snacks') as String,
      isVeg: (json['isVeg'] ?? true) as bool,
      price: basePrice,
      variants: variants,
    );
  }
}
