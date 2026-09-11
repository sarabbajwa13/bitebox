import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../screens/cart_screen.dart';
import '../screens/order_history_screen.dart';
import 'cart_fly.dart';
import 'common.dart';

/// Top branding bar shown on every screen. Includes cart + auth state.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showCart;
  final bool showBack;
  final VoidCallback? onLogoTap;

  /// Fly-to-cart animation ka target — cart icon pe attach hota hai.
  final GlobalKey? cartIconKey;
  const AppHeader({
    super.key,
    this.showCart = true,
    this.showBack = false,
    this.onLogoTap,
    this.cartIconKey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 68,
            child: MaxWidth(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  if (showBack)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Back',
                      ),
                    ),
                  _Logo(onTap: onLogoTap),
                  const Spacer(),
                  if (showCart) const _OrdersButton(),
                  if (showCart) _CartButton(iconKey: cartIconKey),
                  const _LogoutButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final VoidCallback? onTap;
  const _Logo({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 38),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppConfig.businessName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersButton extends StatelessWidget {
  const _OrdersButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
      ),
      icon: const Icon(Icons.receipt_long_outlined),
      color: AppColors.textPrimary,
      tooltip: AppStrings.myOrders,
    );
  }
}

class _CartButton extends StatefulWidget {
  final GlobalKey? iconKey;
  const _CartButton({this.iconKey});

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.35)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.35, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticIn)),
      weight: 55,
    ),
  ]).animate(_bump);

  void _onBump() {
    if (mounted) _bump.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    cartBumpNotifier.addListener(_onBump);
  }

  @override
  void dispose() {
    cartBumpNotifier.removeListener(_onBump);
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().totalQuantity;
    return ScaleTransition(
      scale: _scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            icon: Icon(Icons.shopping_bag_outlined, key: widget.iconKey),
            color: AppColors.textPrimary,
            tooltip: AppStrings.cartTitle,
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple logout icon — sirf logged-in hone pe dikhta hai (history & cart ke beside).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const SizedBox.shrink();
    return IconButton(
      onPressed: () => context.read<AuthProvider>().logout(),
      icon: const Icon(Icons.logout_rounded),
      color: AppColors.textPrimary,
      tooltip: AppStrings.logout,
    );
  }
}
