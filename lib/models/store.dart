import '../config/app_config.dart';

/// A store/agent that sells food and is discoverable within a radius.
class Store {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int deliveryTimeMins;
  final bool isOpen;
  final bool isVeg;

  /// Location + visibility radius (agent app baad me yeh set karegi).
  final double lat;
  final double lng;
  final double radiusKm;

  const Store({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTimeMins,
    required this.isOpen,
    required this.isVeg,
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });

  /// Firestore document → Store.
  factory Store.fromMap(String id, Map<String, dynamic> json) {
    return Store(
      id: id,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      deliveryTimeMins: (json['deliveryTimeMins'] as num?)?.toInt() ?? 30,
      isOpen: (json['isOpen'] ?? true) as bool,
      isVeg: (json['isVeg'] ?? true) as bool,
      lat: (json['lat'] as num?)?.toDouble() ?? AppConfig.userLat,
      lng: (json['lng'] as num?)?.toDouble() ?? AppConfig.userLng,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ??
          AppConfig.defaultStoreRadiusKm,
    );
  }
}
