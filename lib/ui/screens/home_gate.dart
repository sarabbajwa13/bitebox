import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import 'dashboard_screen.dart';
import 'store_detail_screen.dart';

/// App entry point. Stores load karta hai aur decide karta hai:
/// - Radius me sirf 1 store  → seedha uski menu screen ([StoreDetailScreen]).
/// - Warna (0 ya 2+ stores)  → normal [DashboardScreen] listing.
class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> {
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

    // Abhi load ho raha hai — branded splash dikhao.
    if (!provider.hasLoaded) {
      return const _Splash();
    }

    // Single store → seedha menu. Baaki sab cases → dashboard.
    if (provider.hasSingleStore) {
      return StoreDetailScreen(store: provider.singleStore!, isHome: true);
    }
    return const DashboardScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(
                Icons.lunch_dining_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppConfig.businessName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
