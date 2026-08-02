# BiteBox — Client Web App

Doorstep snack delivery ka client-side Flutter **web** app. User apni location ke
radius ke andar wale stores dekhta hai, menu browse karta hai, variants choose
karke quick order create karta hai (name + phone).

> Abhi **static JSON** data pe chal raha hai. Baad me Firebase connect hoga —
> uske liye code centralized aur repository-pattern pe bana hai (neeche dekho).

## Run karna

```bash
flutter pub get
flutter run -d chrome
```

Ya build karke serve:

```bash
flutter build web
```

## Architecture (centralized control)

Poora app is tarah organized hai ki **color, label, assets, config** ek jagah se
control hon:

| Kya badalna hai | Kahan |
| --- | --- |
| Colors / theme / spacing / radius | `lib/config/app_theme.dart` |
| Saare user-facing text / labels | `lib/config/app_strings.dart` |
| Business name, currency, radius, feature flags | `lib/config/app_config.dart` |
| Asset & data file paths | `lib/config/app_assets.dart` |
| Sample data (stores, menus) | `assets/data/*.json` |

```
lib/
├── config/        → theme, strings, assets, config (single source of truth)
├── models/        → Store, MenuItem+Variant, CartItem, Order, AppUser
├── data/
│   └── repositories/
│        ├── data_repository.dart          → abstract interface (UI isi se baat karti hai)
│        └── static_json_repository.dart   → abhi ka JSON impl
├── services/      → location_service.dart (radius filter, Haversine distance)
├── providers/     → auth, cart, store (state — provider package)
├── ui/
│   ├── screens/   → dashboard, store_detail, cart, login, order_success
│   └── widgets/   → app_header, common (VegBadge, SafeImage, QuantityStepper…)
└── main.dart      → providers wiring + data source injection
```

## User flow

Dashboard (radius-filtered store listing) → Store detail → Menu (items +
variants) → Cart → **Place order** pe auth check → agar login nahi to **static
login screen** → name + phone → order confirmation.

## Location / radius

- Abhi **mock location** use hoti hai: `AppConfig.mockUserLat / mockUserLng`.
- Har store ke paas apna `radiusKm` hota hai (JSON me). User store ke radius ke
  andar ho to hi store dikhta hai — nearest-first sorted.
- **Real GPS chahiye:** `lib/services/location_service.dart` me `currentLat` /
  `currentLng` ko `geolocator` se bhar do. Baaki filtering logic same rahega.

## Firebase connect kaise karenge (baad me)

1. `FirebaseRepository` banao jo `DataRepository` interface implement kare.
2. `lib/main.dart` me `StaticJsonRepository()` ko `FirebaseRepository()` se
   replace karo — bas. UI ka koi code nahi badlega.
3. `AuthProvider.login()` ke andar real Firebase Auth call laga do.
4. `AppConfig.useStaticData = false`.

## Notes

- State management: `provider` (lightweight).
- Cart ek hi store ka hota hai — naya store choose karne pe cart reset.
- Login abhi **static** hai (koi real verification nahi) — sirf UI + flow ready.
