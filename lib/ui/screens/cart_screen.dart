import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../data/repositories/data_repository.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/store_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/delivery_location_picker.dart';
import 'login_screen.dart';
import 'order_success_screen.dart';

/// Cart + quick order form. Auth check yahin hota hai place-order pe.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const String _kNameKey = 'customer_name';
  static const String _kLatKey = 'delivery_lat';
  static const String _kLngKey = 'delivery_lng';
  static const String _kDirKey = 'delivery_direction';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _directionCtrl = TextEditingController();
  bool _placing = false;
  bool _prefilled = false;

  /// Map se select ki gayi delivery location.
  LatLng? _deliveryLocation;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  /// Naam + delivery location + direction local storage se prefill.
  /// Kabhi throw nahi karega — storage fail ho to bas prefill nahi hoga.
  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kNameKey);
      final lat = prefs.getDouble(_kLatKey);
      final lng = prefs.getDouble(_kLngKey);
      final dir = prefs.getString(_kDirKey);
      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = name;
        }
        if (dir != null && _directionCtrl.text.isEmpty) {
          _directionCtrl.text = dir;
        }
        if (lat != null && lng != null && _deliveryLocation == null) {
          _deliveryLocation = LatLng(lat, lng);
        }
        _prefsLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _prefsLoaded = true);
    }
  }

  /// Naam type karte hi turant save — taaki agli baar (bina order complete kiye
  /// bhi) prefill ho jaye. Fire-and-forget, kabhi throw nahi karega.
  Future<void> _persistName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNameKey, name.trim());
    } catch (_) {
      // storage unavailable — ignore.
    }
  }

  /// Fire-and-forget: naam + location + direction save (order flow block na kare).
  Future<void> _saveDeliveryPrefs(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNameKey, name);
      await prefs.setString(_kDirKey, _directionCtrl.text.trim());
      if (_deliveryLocation != null) {
        await prefs.setDouble(_kLatKey, _deliveryLocation!.latitude);
        await prefs.setDouble(_kLngKey, _deliveryLocation!.longitude);
      }
    } catch (_) {
      // storage unavailable — ignore.
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _directionCtrl.dispose();
    super.dispose();
  }

  /// Prefill phone from the logged-in user (once).
  void _maybePrefill() {
    if (_prefilled) return;
    final phone = context.read<AuthProvider>().userPhone;
    if (phone != null && phone.isNotEmpty) {
      _phoneCtrl.text = phone.replaceFirst(AppConfig.countryCode, '');
      _prefilled = true;
    }
  }

  /// Phone-OTP login. Success pe phone prefill + rebuild.
  Future<void> _login() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (loggedIn == true && mounted) {
      final phone = context.read<AuthProvider>().userPhone;
      if (phone != null && phone.isNotEmpty) {
        _phoneCtrl.text = phone.replaceFirst(AppConfig.countryCode, '');
      }
      setState(() {});
    }
  }

  Future<void> _onPlaceOrder() async {
    var auth = context.read<AuthProvider>();

    // Step 1: auth check — logged in nahi to phone OTP login karwao.
    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true) return; // cancelled
      if (!mounted) return;
      auth = context.read<AuthProvider>();
      final phone = auth.userPhone;
      if (phone != null && phone.isNotEmpty) {
        _phoneCtrl.text = phone.replaceFirst(AppConfig.countryCode, '');
      }
      setState(() {});
    }

    // Step 2: validate form
    if (!_formKey.currentState!.validate()) return;

    // Delivery location zaroori hai.
    if (_deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery location')),
      );
      return;
    }

    // Providers/context ko async gap se pehle capture kar lo.
    final cart = context.read<CartProvider>();
    final repo = context.read<DataRepository>();
    final ordersProvider = context.read<OrdersProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _placing = true);
    try {
      // Naam + location + direction local storage me save — fire-and-forget.
      unawaited(_saveDeliveryPrefs(_nameCtrl.text.trim()));

      final now = DateTime.now();
      final order = CustomerOrder(
        id: now.millisecondsSinceEpoch.toString().substring(7),
        storeId: cart.storeId ?? '',
        storeName: cart.storeName ?? '',
        customerId: auth.uid ?? '',
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        items: cart.items
            .map((c) => OrderLine(
                  name: c.variant.name,
                  price: c.variant.price,
                  quantity: c.quantity,
                ))
            .toList(),
        total: cart.subtotal,
        createdAt: now,
        statusUpdatedAt: now,
        deliveryLat: _deliveryLocation!.latitude,
        deliveryLng: _deliveryLocation!.longitude,
        deliveryDirection: _directionCtrl.text.trim(),
      );

      // Step 3: place order → Firestore
      final placed = await repo.placeOrder(order);

      // Real-time order history stream start.
      if (auth.uid != null) ordersProvider.start(auth.uid!);
      cart.clear();
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: placed)),
      );
    } catch (e) {
      // Silent fail nahi — error dikhao.
      messenger.showSnackBar(
        SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybePrefill();
    final cart = context.watch<CartProvider>();
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      appBar: const AppHeader(showBack: true, showCart: false),
      body: cart.isEmpty
          ? _EmptyCart(loggedIn: loggedIn, onLogin: _login)
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= AppLayout.mobileBreakpoint;
                return SingleChildScrollView(
                  child: MaxWidth(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _CartList(cart: cart)),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(flex: 2, child: _buildForm(cart)),
                              ],
                            )
                          : Column(
                              children: [
                                _CartList(cart: cart),
                                const SizedBox(height: AppSpacing.lg),
                                _buildForm(cart),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLocationPicker(CartProvider cart) {
    if (!_prefsLoaded) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final store = context.read<StoreProvider>().byId(cart.storeId ?? '');
    final storeLatLng = store != null
        ? LatLng(store.lat, store.lng)
        : const LatLng(AppConfig.fallbackLat, AppConfig.fallbackLng);
    final radiusKm = store?.radiusKm ?? AppConfig.defaultStoreRadiusKm;
    return DeliveryLocationPicker(
      store: storeLatLng,
      radiusKm: radiusKm,
      initial: _deliveryLocation,
      onChanged: (loc) => _deliveryLocation = loc,
    );
  }

  Widget _buildForm(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Delivery details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => unawaited(_persistName(v)),
              decoration: const InputDecoration(
                labelText: AppStrings.yourName,
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.nameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConfig.phoneLength),
              ],
              decoration: const InputDecoration(
                labelText: AppStrings.phoneNumber,
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppStrings.phoneRequired;
                }
                if (v.trim().length != AppConfig.phoneLength) {
                  return AppStrings.phoneInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Delivery location',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'Move the map so the pin is on your location (within the store radius)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildLocationPicker(cart),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _directionCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Direction / landmark (optional)',
                hintText: 'e.g. Near the blue gate, 2nd floor',
                prefixIcon: Icon(Icons.explore_outlined),
              ),
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                const Text(
                  AppStrings.subtotal,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  formatPrice(cart.subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!context.watch<AuthProvider>().isLoggedIn) ...[
              const Text(
                AppStrings.loginToOrderNote,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text(AppStrings.loginCta),
              ),
            ] else
              ElevatedButton(
                onPressed: _placing ? null : _onPlaceOrder,
                child: _placing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.placeOrder),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  final CartProvider cart;
  const _CartList({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                AppStrings.cartTitle,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const Spacer(),
              if (cart.storeName != null)
                Text(
                  cart.storeName!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final line in cart.items) ...[
            Row(
              children: [
                VegBadge(isVeg: line.item.isVeg),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.variant.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatPrice(line.variant.price),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                QuantityStepper(
                  quantity: line.quantity,
                  onAdd: () => context.read<CartProvider>().add(
                    line.item,
                    line.variant,
                    cart.storeName ?? '',
                  ),
                  onRemove: () => context
                      .read<CartProvider>()
                      .decrement(line.item, line.variant),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 64,
                  child: Text(
                    formatPrice(line.lineTotal),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final bool loggedIn;
  final VoidCallback onLogin;
  const _EmptyCart({required this.loggedIn, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.emptyCart,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            AppStrings.emptyCartSubtitle,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          // Logged out → login option (order screen jaisa solid button).
          if (!loggedIn) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text(AppStrings.loginCta),
            ),
          ],
        ],
      ),
    );
  }
}
