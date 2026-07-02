import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appsmarketplace/core/services/dompet_kampus_pay_service.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';
import 'package:appsmarketplace/core/routes/app_router.dart';

class PaymentPendingPage extends StatefulWidget {
  final String reference;
  final double amount;

  const PaymentPendingPage({
    super.key,
    required this.reference,
    required this.amount,
  });

  @override
  State<PaymentPendingPage> createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage>
    with WidgetsBindingObserver {
  late StreamSubscription<PaymentCallbackData> _callbackSubscription;
  Timer? _pollingTimer;
  bool _isSuccess = false;
  bool _isFailed = false;
  bool _payLaunched = false; // track apakah app sudah dibuka
  String _statusMessage = 'Menunggu Pembayaran...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Subscribe ke stream callback deeplink
    _callbackSubscription =
        DompetKampusPayService.instance.onCallback.listen((data) {
      debugPrint(
          '[PaymentPendingPage] Callback diterima: ${data.status}, ref: ${data.reference}');
      // Cocokkan reference agar tidak salah order
      if (data.reference == widget.reference || data.reference.isEmpty) {
        _processPaymentCallback(data.status, data.transactionId);
      }
    });

    // 2. Auto-launch & cek cold start setelah frame pertama rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLaunchDompetKampus();
      _checkColdStartCallback();
    });

    // 3. Fallback polling setiap 5 detik
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callbackSubscription.cancel(); // WAJIB: cegah memory leak
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Deteksi kembali dari app lain (Dompet Kampus Global → Pasar Malam)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _payLaunched) {
      debugPrint(
          '[PaymentPendingPage] App resumed setelah launch DKG — cek status backend.');
      _checkStatusBackend();
    }
  }

  /// Auto-launch Dompet Kampus Global saat halaman dibuka.
  Future<void> _autoLaunchDompetKampus() async {
    final urlStr = DompetKampusPayService.buildDeeplinkUrl(
      reference: widget.reference,
      amount: widget.amount,
    );
    debugPrint('[PaymentPendingPage] Deeplink URL: $urlStr');

    final uri = Uri.parse(urlStr);

    try {
      // Coba canLaunchUrl terlebih dahulu
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('[PaymentPendingPage] canLaunchUrl: $canLaunch');

      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) setState(() => _payLaunched = true);
      } else {
        // Perbaikan 2: bypass — coba launch langsung (false-negative fix)
        debugPrint(
            '[PaymentPendingPage] canLaunchUrl false → mencoba launchUrl langsung...');
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) setState(() => _payLaunched = true);
        } catch (launchErr) {
          debugPrint('[PaymentPendingPage] launchUrl langsung juga gagal: $launchErr');
          if (mounted) _showAppNotFoundDialog();
        }
      }
    } catch (e) {
      debugPrint('[PaymentPendingPage] Error launching deeplink: $e');
      if (mounted) _showAppNotFoundDialog();
    }
  }

  void _showAppNotFoundDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aplikasi Tidak Ditemukan'),
        content: const Text(
          'Aplikasi Dompet Kampus Global tidak terinstal di perangkat ini.\n\n'
          'Pastikan aplikasi sudah terinstal untuk melanjutkan pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  /// Cek jika ada callback yang sudah masuk sebelum widget ini siap (cold start).
  void _checkColdStartCallback() {
    final pending = DompetKampusPayService.instance.consumePendingCallback();
    if (pending != null) {
      debugPrint(
          '[PaymentPendingPage] Cold-start callback ditemukan: ${pending.status}');
      if (pending.reference == widget.reference || pending.reference.isEmpty) {
        _processPaymentCallback(pending.status, pending.transactionId);
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatusBackend();
    });
  }

  Future<void> _checkStatusBackend() async {
    if (_isSuccess || _isFailed) return;

    try {
      final res =
          await DioClient.instance.get('/orders/status/${widget.reference}');
      final status = res.data['data']['status'] as String;
      debugPrint('[PaymentPendingPage] Status dari backend: $status');

      if (status == 'success') {
        _handlePaymentSuccess();
      } else if (status == 'failed') {
        _handlePaymentFailure('Pembayaran dibatalkan atau gagal di sistem.');
      }
    } catch (e) {
      debugPrint('[PaymentPendingPage] Error polling backend: $e');
    }
  }

  Future<void> _processPaymentCallback(
      String status, String transactionId) async {
    if (_isSuccess || _isFailed) return;

    setState(() => _statusMessage = 'Memverifikasi pembayaran...');

    try {
      // Konfirmasi ke backend
      await DioClient.instance.post('/orders/confirm', data: {
        'reference': widget.reference,
        'status': status,
        'transaction_id': transactionId,
      });

      if (status == 'success') {
        _handlePaymentSuccess();
      } else {
        _handlePaymentFailure('Pembayaran gagal dilakukan.');
      }
    } catch (e) {
      debugPrint('[PaymentPendingPage] Error konfirmasi callback: $e');
      // Jika backend tidak bisa dikonfirmasi tapi callback sukses, tetap tampilkan sukses
      if (status == 'success') {
        _handlePaymentSuccess();
      } else {
        _handlePaymentFailure('Gagal sinkronisasi status pembayaran.');
      }
    }
  }

  void _handlePaymentSuccess() {
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isSuccess = true;
        _statusMessage = 'Pembayaran Berhasil! 🎉';
      });
    }
  }

  void _handlePaymentFailure(String message) {
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isFailed = true;
        _statusMessage = message;
      });
    }
  }

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pembayaran'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── STATUS ICON ──
              if (!_isSuccess && !_isFailed) ...[
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(strokeWidth: 6),
                ),
              ] else if (_isSuccess) ...[
                Icon(Icons.check_circle, size: 100, color: Colors.green.shade600),
              ] else ...[
                Icon(Icons.cancel, size: 100, color: Colors.red.shade600),
              ],
              const SizedBox(height: 32),

              // ── STATUS MESSAGE ──
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ── ORDER DETAILS ──
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Order ID/Ref', widget.reference, theme),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Nominal',
                        'Rp ${_formatPrice(widget.amount)}',
                        theme,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          'Metode Pembayaran', 'Dompet Kampus Global', theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── ACTION BUTTONS ──
              if (!_isSuccess && !_isFailed) ...[
                // Langkah yang sudah selesai
                if (_payLaunched)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border:
                          Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Dompet Kampus Global telah dibuka',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Text(
                  _payLaunched
                      ? 'Selesaikan pembayaran di Dompet Kampus Global, lalu kembali ke sini.'
                      : 'Silakan selesaikan pembayaran Anda di aplikasi Dompet Kampus.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _autoLaunchDompetKampus,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(_payLaunched
                      ? 'Buka Kembali Dompet Kampus'
                      : 'Buka Dompet Kampus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRouter.dashboard, (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali ke Beranda (Bayar Nanti)'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _checkStatusBackend,
                  child: const Text('Cek Status Manual'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRouter.dashboard, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme,
      {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPrimary ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
