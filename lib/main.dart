import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'data/repositories/data_repository.dart';
import 'data/repositories/firebase_repository.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/store_provider.dart';
import 'services/location_service.dart';
import 'ui/screens/home_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BiteBoxApp());
}

class BiteBoxApp extends StatelessWidget {
  const BiteBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final DataRepository repository = FirebaseRepository();
    final locationService = LocationService();

    return MultiProvider(
      providers: [
        Provider<DataRepository>.value(value: repository),
        Provider<LocationService>.value(value: locationService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => OrdersProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => StoreProvider(
            repository: repository,
            locationService: locationService,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.businessName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeGate(),
      ),
    );
  }
}
