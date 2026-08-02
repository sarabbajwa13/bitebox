import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';

/// Format a price with the configured currency symbol.
String formatPrice(num value) {
  final s = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '${AppConfig.currencySymbol}$s';
}

/// Full-screen image viewer — image center me bada, upar center me cross icon.
/// Pinch/drag se zoom bhi ho sakta hai.
void showFullImage(BuildContext context, String url) {
  if (url.trim().isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (ctx) {
      final size = MediaQuery.of(ctx).size;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cross icon — image ke just upar, horizontally center.
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.black, size: 26),
              ),
            ),
            // Image (full size, contain).
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.92,
                  maxHeight: size.height * 0.75,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Image not available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Accent color for an order status.
Color statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.accent; // amber
    case OrderStatus.rejected:
      return AppColors.danger;
    case OrderStatus.delivered:
      return AppColors.success;
    case OrderStatus.accepted:
    case OrderStatus.preparing:
    case OrderStatus.outForDelivery:
      return AppColors.primary;
  }
}

/// Icon for an order status (used in the progress tracker).
IconData statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.hourglass_top_rounded;
    case OrderStatus.accepted:
      return Icons.check_circle_outline_rounded;
    case OrderStatus.preparing:
      return Icons.restaurant_rounded;
    case OrderStatus.outForDelivery:
      return Icons.delivery_dining_rounded;
    case OrderStatus.delivered:
      return Icons.home_rounded;
    case OrderStatus.rejected:
      return Icons.cancel_outlined;
  }
}

/// Small rounded status chip.
class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small veg / non-veg indicator square.
class VegBadge extends StatelessWidget {
  final bool isVeg;
  final double size;
  const VegBadge({super.key, required this.isVeg, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.veg : AppColors.nonVeg;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: size * 0.5,
          height: size * 0.5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Network image with rounded corners + graceful placeholder/error states.
class SafeImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.md,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(showSpinner: true);
        },
        errorBuilder: (context, error, stack) => _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool showSpinner = false}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF3ECE4),
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(
                Icons.restaurant_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
      ),
    );
  }
}

/// Compact +/- quantity stepper used on menu items and cart.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(Icons.remove_rounded, onRemove),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                fontSize: 15,
              ),
            ),
          ),
          _iconBtn(Icons.add_rounded, onAdd),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppColors.primaryDark),
      ),
    );
  }
}

/// Centers content and caps its width on large screens (premium web layout).
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  const MaxWidth({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
