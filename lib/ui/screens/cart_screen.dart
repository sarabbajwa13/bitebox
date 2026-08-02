import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/app_header.dart';
import '../widgets/common.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _placing = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  /// Pichli baar enter kiya naam local storage se prefill (editable rahega).
  /// Kabhi throw nahi karega — storage fail ho to bas prefill nahi hoga.
  Future<void> _loadSavedName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_kNameKey);
      if (name != null &&
          name.isNotEmpty &&
          mounted &&
          _nameCtrl.text.isEmpty) {
        _nameCtrl.text = name;
      }
    } catch (_) {
      // storage unavailable — ignore.
    }
  }

  /// Fire-and-forget: naam save karo, par order flow ko kabhi block/break na karo.
  Future<void> _saveName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kNameKey, name);
    } catch (_) {
      // storage unavailable — ignore.
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
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

    // Providers/context ko async gap se pehle capture kar lo.
    final cart = context.read<CartProvider>();
    final repo = context.read<DataRepository>();
    final ordersProvider = context.read<OrdersProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _placing = true);
    try {
      // Naam local storage me save — fire-and-forget (order ko block na kare).
      unawaited(_saveName(_nameCtrl.text.trim()));

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

    return Scaffold(
      appBar: const AppHeader(showBack: true, showCart: false),
      body: cart.isEmpty
          ? const _EmptyCart()
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
  const _EmptyCart();

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
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.continueShopping),
          ),
        ],
      ),
    );
  }
}
