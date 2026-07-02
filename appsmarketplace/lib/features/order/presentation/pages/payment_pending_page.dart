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

class _PaymentPendingPageState extends State<PaymentPendingPage> with WidgetsBindingObserver {
  late StreamSubscription<PaymentCallbackData> _callbackSubscription;
  Timer? _pollingTimer;
  bool _isSuccess = false;
  bool _isFailed = false;
  String _statusMessage = 'Menunggu Pembayaran...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Subscribe to the deep link callback stream
    _callbackSubscription = DompetKampusPayService.instance.onCallback.listen((data) {
      if (data.reference == widget.reference) {
        _processPaymentCallback(data.status, data.transactionId);
      }
    });

    // 2. Setup PostFrameCallback for Auto-launch & Cold start handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLaunchDompetKampus();
      _checkColdStartCallback();
    });

    // 3. Start fallback polling (every 5 seconds)
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callbackSubscription.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Detect when user returns back to the application
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, check status on backend immediately.');
      _checkStatusBackend();
    }
  }

  void _autoLaunchDompetKampus() async {
    final urlStr = DompetKampusPayService.buildDeeplinkUrl(
      reference: widget.reference,
      amount: widget.amount,
    );
    final uri = Uri.parse(urlStr);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Cannot launch deep link URL automatically, showing manual open button.');
      }
    } catch (e) {
      debugPrint('Error launching deep link: $e');
    }
  }

  void _checkColdStartCallback() {
    final pending = DompetKampusPayService.instance.consumePendingCallback();
    if (pending != null && pending.reference == widget.reference) {
      _processPaymentCallback(pending.status, pending.transactionId);
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
      final res = await DioClient.instance.get('/orders/status/${widget.reference}');
      final status = res.data['data']['status'] as String;

      if (status == 'success') {
        _handlePaymentSuccess();
      } else if (status == 'failed') {
        _handlePaymentFailure('Pembayaran dibatalkan atau gagal di sistem.');
      }
    } catch (e) {
      debugPrint('Error polling status from backend: $e');
    }
  }

  Future<void> _processPaymentCallback(String status, String transactionId) async {
    if (_isSuccess || _isFailed) return;

    setState(() {
      _statusMessage = 'Memverifikasi pembayaran...';
    });

    try {
      // 1. Confirm status update with backend
      await DioClient.instance.post('/orders/confirm', data: {
        'reference': widget.reference,
        'status': status,
        'transaction_id': transactionId,
      });

      // 2. Update UI based on confirmed status
      if (status == 'success') {
        _handlePaymentSuccess();
      } else {
        _handlePaymentFailure('Pembayaran gagal dilakukan.');
      }
    } catch (e) {
      debugPrint('Error confirming payment callback: $e');
      _handlePaymentFailure('Gagal sinkronisasi status pembayaran.');
    }
  }

  void _handlePaymentSuccess() {
    _pollingTimer?.cancel();
    setState(() {
      _isSuccess = true;
      _statusMessage = 'Pembayaran Berhasil! 🎉';
    });
  }

  void _handlePaymentFailure(String message) {
    _pollingTimer?.cancel();
    setState(() {
      _isFailed = true;
      _statusMessage = message;
    });
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
              // --- STATUS ICON ---
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

              // --- STATUS MESSAGE ---
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // --- ORDER DETAILS ---
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Order ID/Ref', widget.reference, theme),
                      const SizedBox(height: 8),
                      _buildDetailRow('Nominal', 'Rp ${_formatPrice(widget.amount)}', theme, isPrimary: true),
                      const SizedBox(height: 8),
                      _buildDetailRow('Metode Pembayaran', 'Dompet Kampus Global', theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- ACTION BUTTONS ---
              if (!_isSuccess && !_isFailed) ...[
                Text(
                  'Silakan selesaikan pembayaran Anda di aplikasi Dompet Kampus.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _autoLaunchDompetKampus,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Buka Dompet Kampus'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRouter.dashboard, (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali ke Beranda (Bayar Nanti)'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, AppRouter.dashboard, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildDetailRow(String label, String value, ThemeData theme, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
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
