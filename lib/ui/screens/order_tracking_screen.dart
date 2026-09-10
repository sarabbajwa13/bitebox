import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/delivery_location_picker.dart';

/// Live order status tracker with a vertical progress timeline (Firestore
/// real-time — agent ke status update pe live badalta hai).
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().uid;
      if (uid != null) context.read<OrdersProvider>().start(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final order = provider.byId(widget.orderId);

    return Scaffold(
      appBar: const AppHeader(showBack: true, showCart: false),
      body: order == null
          ? Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Order not found'),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: [
                MaxWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(order: order),
                      const SizedBox(height: AppSpacing.lg),
                      _StatusCard(order: order),
                      const SizedBox(height: AppSpacing.lg),
                      _ItemsCard(order: order),
                      if (order.hasLocation) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _DeliveryCard(order: order),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final CustomerOrder order;
  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.orderStatusTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            StatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Order #${order.id} · ${order.storeName}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final CustomerOrder order;
  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: order.status.isRejected
          ? _RejectedView()
          : _Timeline(current: order.status),
    );
  }
}

/// Vertical stepper across [kOrderPipeline].
class _Timeline extends StatelessWidget {
  final OrderStatus current;
  const _Timeline({required this.current});

  @override
  Widget build(BuildContext context) {
    final currentIndex = kOrderPipeline.indexOf(current);
    return Column(
      children: [
        for (int i = 0; i < kOrderPipeline.length; i++)
          _TimelineStep(
            status: kOrderPipeline[i],
            done: i < currentIndex,
            active: i == currentIndex,
            isLast: i == kOrderPipeline.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final OrderStatus status;
  final bool done;
  final bool active;
  final bool isLast;
  const _TimelineStep({
    required this.status,
    required this.done,
    required this.active,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final reached = done || active;
    final color = reached ? statusColor(status) : AppColors.border;
    final textColor = reached ? AppColors.textPrimary : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node + connecting line.
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: reached ? color : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: reached ? color : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : statusIcon(status),
                  size: 18,
                  color: reached ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    color: done ? statusColor(status) : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Labels.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: reached
                          ? AppColors.textSecondary
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel_outlined,
            color: AppColors.danger,
            size: 44,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          OrderStatus.rejected.label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          AppStrings.orderRejectedNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final CustomerOrder order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    '${line.quantity}× ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Expanded(child: Text(line.name)),
                  Text(formatPrice(line.lineTotal)),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              Text(
                formatPrice(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final CustomerOrder order;
  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.danger),
              SizedBox(width: 6),
              Text(
                'Delivery location',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LocationMapPreview(
            location: LatLng(order.deliveryLat!, order.deliveryLng!),
          ),
          if (order.deliveryDirection.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.explore_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryDirection,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(AppRadius.lg),
  border: Border.all(color: AppColors.border),
);
