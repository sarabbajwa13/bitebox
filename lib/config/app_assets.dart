/// Central registry of asset + data paths.
///
/// Assets add karte waqt sirf yahan path likho, poori app referenced rahegi.
class AppAssets {
  AppAssets._();

  // Static JSON data (bundled). Firebase ke baad yeh replace ho jayega.
  static const String storesData = 'assets/data/stores.json';
  static const String menusData = 'assets/data/menus.json';

  // Placeholder images abhi network se aati hain (JSON me url). Baad me
  // local assets chahiye to yahan add kar dena, e.g.:
  // static const String logo = 'assets/images/logo.png';
}
