import 'package:appsmarketplace/core/services/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Pages
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/Register_page.dart';
import '../features/auth/presentation/pages/Verify_email_page.dart';
import '../features/auth/presentation/pages/dashboard_page.dart';
import 'package:appsmarketplace/features/order/presentation/pages/checkout_page.dart';
import 'package:appsmarketplace/features/order/presentation/pages/payment_pending_page.dart';

import '../services/secure_storage.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String dashboard = '/dashboard';
  static const String checkout = '/checkout';
  static const String paymentPending = '/payment-pending';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    verifyEmail: (_) => const VerifyEmailPage(),

    // Dashboard dibungkus AuthGuard (Si Satpam)
    dashboard: (_) => const AuthGuard(child: DashboardPage()),
    checkout: (_) => const CheckoutPage(),
    paymentPending: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PaymentPendingPage(
        reference: args['reference'] as String,
        amount: args['amount'] as double,
      );
    },
  };
}

// --- TULIS KODE INI DI BAWAH CLASS APPROUTER (Masih di file yang sama) ---

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Memantau status login dari AuthProvider
    // Status ini didapat setelah login sukses atau cek token di awal
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.authenticated => child, // Jika OK, tampilkan Dashboard
      AuthStatus.emailNotVerified =>
        const VerifyEmailPage(), // Jika login tapi belum klik link email
      _ => const LoginPage(), // Jika belum login, tendang ke Login Page
    };
  }
}

// SplashPage: cek token tersimpan, redirect otomatis
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Animasi splash
    if (!mounted) return;

    final token = await SecureStorage.getToken();
    final route = token != null ? AppRouter.dashboard : AppRouter.login;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
