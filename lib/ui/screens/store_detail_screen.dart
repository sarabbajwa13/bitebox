import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../data/repositories/data_repository.dart';
import '../../models/menu_item.dart';
import '../../models/store.dart';
import '../../providers/cart_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/cart_fly.dart';
import '../widgets/common.dart';
import '../widgets/policy_footer.dart';
import 'cart_screen.dart';

/// Store detail — shows the store's menu grouped by category.
class StoreDetailScreen extends StatefulWidget {
  final Store store;

  /// True jab ye screen app ka home ho (radius me single store). Tab header me
  /// back button nahi dikhega (peeche jaane ke liye koi listing nahi hai).
  final bool isHome;

  const StoreDetailScreen({
    super.key,
    required this.store,
    this.isHome = false,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  late Future<List<MenuItem>> _menuFuture;

  /// Fly-to-cart animation ka target (header ke cart icon pe attach).
  final GlobalKey _cartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _menuFuture = context.read<DataRepository>().getMenuForStore(
      widget.store.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(showBack: !widget.isHome, cartIconKey: _cartKey),
      // Cart bar ko Stack me floating overlay rakha hai (bottomNavigationBar
      // nahi) — warna Flutter web pe empty→visible toggle hone par Scaffold
      // re-layout se body blank ho jaati thi.
      body: CartFlyTarget(
        cartKey: _cartKey,
        child: Stack(
        children: [
          FutureBuilder<List<MenuItem>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              final grouped = <String, List<MenuItem>>{};
              for (final item in items) {
                grouped.putIfAbsent(item.category, () => []).add(item);
              }

              return ListView(
                // Extra bottom padding taaki aakhri item floating cart bar ke
                // peeche na chhupe.
                padding: const EdgeInsets.only(bottom: 104),
                children: [
                  _StoreBanner(store: widget.store),
                  MaxWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          AppStrings.menuTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final entry in grouped.entries)
                          _CategorySection(
                            title: entry.key,
                            items: entry.value,
                            storeName: widget.store.name,
                          ),
                      ],
                    ),
                  ),
                  const PolicyFooter(),
                ],
              );
            },
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CartBar(),
          ),
        ],
        ),
      ),
    );
  }
}

class _StoreBanner extends StatelessWidget {
  final Store store;
  const _StoreBanner({required this.store});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeImage(
          url: store.imageUrl,
          height: 220,
          width: double.infinity,
          radius: 0,
        ),
        MaxWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegBadge(isVeg: store.isVeg, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        store.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  store.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: 2),
                    Text(store.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${store.deliveryTimeMins} min',
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<MenuItem> items;
  final String storeName;
  const _CategorySection({
    required this.title,
    required this.items,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        for (final item in items)
          _MenuItemCard(item: item, storeName: storeName),
      ],
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final String storeName;
  const _MenuItemCard({required this.item, required this.storeName});

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  /// Fly-to-cart animation ka source (is item ki image).
  final GlobalKey _imgKey = GlobalKey();

  void _fly() {
    final target = CartFlyTarget.maybeOf(context);
    if (target == null) return;
    flyToCart(
      context: context,
      sourceKey: _imgKey,
      cartKey: target.cartKey,
      imageUrl: widget.item.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final heroTag = 'menu-img-${item.id}';
    return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VegBadge(isVeg: item.isVeg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.hasMultipleVariants
                      ? 'From ${formatPrice(item.startingPrice)}'
                      : formatPrice(item.startingPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
            const SizedBox(width: AppSpacing.md),
            Column(
              children: [
                GestureDetector(
                  // Sirf image pe tap → full-size (thumbnail se grow hoke).
                  onTap: () =>
                      showFullImage(context, item.imageUrl, heroTag: heroTag),
                  child: Hero(
                    tag: heroTag,
                    child: SafeImage(
                      key: _imgKey,
                      url: item.imageUrl,
                      width: 110,
                      height: 90,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _AddControl(
                  item: item,
                  storeName: widget.storeName,
                  onFly: _fly,
                ),
              ],
            ),
          ],
        ),
      );
  }
}

/// Add button — single variant adds directly; multiple opens a picker sheet.
class _AddControl extends StatelessWidget {
  final MenuItem item;
  final String storeName;

  /// Add/plus dabne par fly-to-cart animation chalane ke liye.
  final VoidCallback onFly;
  const _AddControl({
    required this.item,
    required this.storeName,
    required this.onFly,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (!item.hasMultipleVariants) {
      final variant = item.sellableVariants.first;
      final qty = cart.quantityOf(item.id, variant.id);
      if (qty == 0) {
        return SizedBox(
          width: 110,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () {
              onFly();
              context.read<CartProvider>().add(item, variant, storeName);
            },
            child: const Text(
              AppStrings.addToCart,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      }
      return QuantityStepper(
        width: 110,
        quantity: qty,
        onAdd: () {
          onFly();
          context.read<CartProvider>().add(item, variant, storeName);
        },
        onRemove: () => context.read<CartProvider>().decrement(item, variant),
      );
    }

    // Multiple variants → show total added, open picker.
    final totalForItem = item.sellableVariants.fold<int>(
      0,
      (sum, v) => sum + cart.quantityOf(item.id, v.id),
    );
    return SizedBox(
      width: 110,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: () => _openVariantPicker(context),
        child: Text(
          totalForItem > 0 ? '$totalForItem in cart' : AppStrings.addToCart,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _openVariantPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _VariantSheet(item: item, storeName: storeName),
    );
  }
}

class _VariantSheet extends StatelessWidget {
  final MenuItem item;
  final String storeName;
  const _VariantSheet({required this.item, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              AppStrings.chooseVariant,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final variant in item.sellableVariants)
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  final qty = cart.quantityOf(item.id, variant.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        VegBadge(isVeg: item.isVeg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formatPrice(variant.price),
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (qty == 0)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onPressed: () => context
                                .read<CartProvider>()
                                .add(item, variant, storeName),
                            child: const Text(
                              AppStrings.addToCart,
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          )
                        else
                          QuantityStepper(
                            quantity: qty,
                            onAdd: () => context
                                .read<CartProvider>()
                                .add(item, variant, storeName),
                            onRemove: () => context
                                .read<CartProvider>()
                                .decrement(item, variant),
                          ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky bottom bar showing cart summary + go-to-cart.
class _CartBar extends StatelessWidget {
  const _CartBar();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: MaxWidth(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.totalQuantity} ${AppStrings.items}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    formatPrice(cart.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(AppStrings.cartTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
