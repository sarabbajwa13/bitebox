/// Central business + feature configuration for BiteBox (client).
class AppConfig {
  AppConfig._();

  static const String businessName = 'BiteBox';
  static const String tagline = 'Fresh snacks, delivered to your door';

  /// Currency symbol used across the app (agent app se match).
  static const String currencySymbol = '₹';

  /// Firestore collection names (agent app se match karna chahiye).
  static const String storesCollection = 'stores';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';

  /// ----- Location / radius -----
  /// Customer ki configured location (store ke paas — store hamesha radius me
  /// dikhe). Baad me real GPS pe switch easy.
  static const double userLat = 28.6139;
  static const double userLng = 77.2090;

  /// Agar store me radius na ho to default.
  static const double defaultStoreRadiusKm = 5.0;

  /// ----- Auth (phone OTP) -----
  static const int phoneLength = 10;
  static const String countryCode = '+91';
  static const int otpLength = 6;
}
