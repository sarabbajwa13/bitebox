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
  final List<Variant> variants;

  const MenuItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.isVeg,
    required this.variants,
  });

  /// Lowest variant price — used for "from ₹X" display.
  double get startingPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  bool get hasMultipleVariants => variants.length > 1;

  /// Firestore `products` document → MenuItem.
  factory MenuItem.fromMap(String id, Map<String, dynamic> json) {
    return MenuItem(
      id: id,
      storeId: (json['storeId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      category: (json['category'] ?? 'Snacks') as String,
      isVeg: (json['isVeg'] ?? true) as bool,
      variants: ((json['variants'] as List<dynamic>?) ?? [])
          .map((v) => Variant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
