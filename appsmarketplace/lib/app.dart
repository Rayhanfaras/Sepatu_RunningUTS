import 'package:appsmarketplace/core/providers/theme_provider.dart';
import 'package:appsmarketplace/core/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/features/dashboard/presentation/providers/product_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'My App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light, // ← dipakai saat ThemeMode.light
            darkTheme: AppTheme.dark, // ← dipakai saat ThemeMode.dark
            themeMode: themeProvider.themeMode,
            // ↑ berubah saat toggle() dipanggil → seluruh app ikut
            initialRoute: AppRouter.splash,
            routes: AppRouter.routes,
          );
        },
      ),
    );
  }
}
