import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../widgets/common.dart';
import 'order_tracking_screen.dart';

/// Simple order confirmation screen.
class OrderSuccessScreen extends StatelessWidget {
  final CustomerOrder order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F6EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.orderPlacedTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  AppStrings.orderPlacedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Summary(order: order),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            OrderTrackingScreen(orderId: order.id),
                      ),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text(AppStrings.trackOrder),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Text(AppStrings.continueShopping),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CustomerOrder order;
  const _Summary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              const Icon(Icons.receipt_long_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Order #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Text(order.storeName,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final line in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('${line.quantity}× ',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Expanded(child: Text(line.name)),
                  Text(formatPrice(line.lineTotal)),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text(formatPrice(order.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
