import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../models/store.dart';
import '../../providers/store_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/policy_footer.dart';
import 'store_detail_screen.dart';

/// Landing dashboard — radius-filtered store listing.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StoreProvider>();
      if (!provider.hasLoaded && !provider.isLoading) {
        provider.loadStores();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final stores = provider.visibleStores
        .where(
          (s) =>
              _query.isEmpty ||
              s.name.toLowerCase().contains(_query.toLowerCase()) ||
              s.description.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: () => provider.reload(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const _Hero(),
            MaxWidth(
              child: _SearchBar(
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              MaxWidth(child: _ErrorState(message: provider.error!))
            else if (provider.locationDenied)
              MaxWidth(
                child: _LocationOffState(
                  onRetry: () => provider.reload(),
                  diagnostic: provider.locationError,
                ),
              )
            else if (stores.isEmpty)
              const MaxWidth(child: _EmptyState())
            else
              MaxWidth(child: _StoreGrid(stores: stores, provider: provider)),
            const PolicyFooter(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1E3), Color(0xFFFFF9F4)],
        ),
      ),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.nearbyStores,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppConfig.tagline,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: AppStrings.searchHint,
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _StoreGrid extends StatelessWidget {
  final List<Store> stores;
  final StoreProvider provider;
  const _StoreGrid({required this.stores, required this.provider});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1000
        ? 3
        : width >= AppLayout.mobileBreakpoint
        ? 2
        : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stores.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisExtent: 300,
      ),
      itemBuilder: (context, i) {
        final store = stores[i];
        return _StoreCard(
          store: store,
          distanceKm: provider.distanceToStore(store),
        );
      },
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;
  final double distanceKm;
  const _StoreCard({required this.store, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: store.isOpen
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StoreDetailScreen(store: store),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SafeImage(
                  url: store.imageUrl,
                  height: 150,
                  width: double.infinity,
                  radius: 0,
                ),
                if (!store.isOpen)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: Text(
                          AppStrings.closedLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Pill(
                    icon: Icons.near_me_rounded,
                    label: '${distanceKm.toStringAsFixed(1)} ${AppStrings.km}',
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VegBadge(isVeg: store.isVeg),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${store.deliveryTimeMins} min',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.noStoresTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            AppStrings.noStoresSubtitle,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LocationOffState extends StatelessWidget {
  final VoidCallback onRetry;
  final String? diagnostic;
  const _LocationOffState({required this.onRetry, this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_rounded,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.locationOffTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              AppStrings.locationOffSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (diagnostic != null && diagnostic!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                diagnostic!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Something went wrong\n$message', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
