import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';
import 'package:appsmarketplace/core/features/dashboard/presentation/providers/product_provider.dart';
import 'package:appsmarketplace/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_provider.dart' as auth_provider;
import 'package:appsmarketplace/core/services/dompet_kampus_pay_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await DompetKampusPayService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
