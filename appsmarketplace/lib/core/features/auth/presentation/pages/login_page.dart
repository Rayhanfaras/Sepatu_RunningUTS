import 'package:appsmarketplace/core/routes/app_router.dart';
import 'package:appsmarketplace/core/services/auth_provider.dart'
    as auth_provider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/custom_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/divider_with_text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Handler untuk login email/password
  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<auth_provider.AuthProvider>();
    final success = await auth.loginWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    // 🔥 TAMBAH INI
    print("LOGIN SUCCESS: $success");
    print("STATUS: ${auth.status}");
    print("ERROR: ${auth.errorMessage}");

    if (!mounted) return;

    if (success) {
      // Menggunakan Future.microtask untuk memastikan navigasi aman dari konflik build
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        }
      });
    } else {
      // Jika butuh verifikasi email
      if (auth.status == auth_provider.AuthStatus.emailNotVerified) {
        Future.microtask(() {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
          }
        });
      } else {
        _showError(auth.errorMessage ?? 'Login gagal');
      }
    }
  }

  /// Handler untuk login Google
  Future<void> _loginGoogle() async {
    final auth = context.read<auth_provider.AuthProvider>();
    final success = await auth.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } else {
      if (auth.status == auth_provider.AuthStatus.emailNotVerified) {
        Navigator.pushReplacementNamed(context, AppRouter.verifyEmail);
      } else {
        _showError(auth.errorMessage ?? 'Login Google gagal');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Memantau status loading dari provider
    final authWatch = context.watch<auth_provider.AuthProvider>();
    final isLoading = authWatch.isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Sedang masuk...',
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const AuthHeader(
                      icon: Icons.lock_person_rounded,
                      title: 'Selamat Datang',
                      subtitle:
                          'Silakan masuk untuk mengakses Maduras\'s Jerseys',
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: 'Email',
                      hint: 'Masukkan email anda',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Email tidak boleh kosong';
                        if (!EmailValidator.validate(v))
                          return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      hint: 'Masukkan password anda',
                      controller: _passCtrl,
                      obscureText: !_showPass,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPass ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password tidak boleh kosong'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implementasi reset password dialog
                        },
                        child: const Text('Lupa Password?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'MASUK',
                      onPressed: isLoading ? null : _loginEmail,
                    ),
                    const SizedBox(height: 24),
                    const DividerWithText(text: 'Atau'),
                    const SizedBox(height: 24),
                    GoogleSignInButton(
                      onPressed: isLoading ? null : _loginGoogle,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? '),
                        GestureDetector(
                          onTap: () {
                            if (!isLoading) {
                              Navigator.pushNamed(context, AppRouter.register);
                            }
                          },
                          child: const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
