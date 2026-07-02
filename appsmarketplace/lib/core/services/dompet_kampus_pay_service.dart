import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Model data yang diterima saat Dompet Kampus Global memanggil callback.
class PaymentCallbackData {
  final String status;
  final String reference;
  final String transactionId;

  const PaymentCallbackData({
    required this.status,
    required this.reference,
    required this.transactionId,
  });

  /// Helper agar tidak perlu membandingkan string di mana-mana.
  bool get isSuccess => status == 'success';

  @override
  String toString() =>
      'PaymentCallbackData(status: $status, reference: $reference, transactionId: $transactionId)';
}

/// Service singleton untuk menangani deeplink dua arah dengan Dompet Kampus Global.
///
/// Outgoing : Pasar Malam → dompetkampus://pay?...
/// Incoming  : pasarmalam://payment-callback?status=success&reference=INV-42
class DompetKampusPayService {
  // ───────────────── Singleton ─────────────────
  static final DompetKampusPayService _instance =
      DompetKampusPayService._internal();

  factory DompetKampusPayService() => _instance;

  /// Alias statis agar kode lama (DompetKampusPayService.instance) tetap bekerja.
  static DompetKampusPayService get instance => _instance;

  DompetKampusPayService._internal();

  // ───────────────── Stream ─────────────────
  /// BroadcastStream: boleh punya banyak listener sekaligus.
  final _callbackController =
      StreamController<PaymentCallbackData>.broadcast();

  Stream<PaymentCallbackData> get onCallback => _callbackController.stream;

  // ───────────────── Cold-start buffer ─────────────────
  /// Simpan callback yang datang sebelum widget tree siap (cold start).
  PaymentCallbackData? _pendingCallback;

  /// Konsumsi sekali — setelah diambil, dihapus dari buffer.
  PaymentCallbackData? consumePendingCallback() {
    final data = _pendingCallback;
    _pendingCallback = null;
    return data;
  }

  // ───────────────── Inisialisasi ─────────────────
  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('[DKPayService] Web platform — skip deeplink init.');
      return;
    }

    final appLinks = AppLinks();

    // KASUS 1: App dibuka oleh deeplink (cold start)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DKPayService] Cold-start URI: $initialUri');
        _handleUri(initialUri, isColdStart: true);
      }
    } catch (e) {
      debugPrint('[DKPayService] Failed to get initial link: $e');
    }

    // KASUS 2: Deeplink masuk saat app sudah berjalan (background / foreground)
    appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) =>
          debugPrint('[DKPayService] URI stream error: $err'),
    );
  }

  // ───────────────── Handler ─────────────────
  void _handleUri(Uri uri, {bool isColdStart = false}) {
    debugPrint('[DKPayService] URI diterima: $uri');
    debugPrint('[DKPayService] Cold start: $isColdStart');

    // Hanya proses URI callback dari Dompet Kampus Global
    if (uri.scheme == 'pasarmalam' && uri.host == 'payment-callback') {
      final status = uri.queryParameters['status'] ?? 'unknown';
      final reference = uri.queryParameters['reference'] ?? '';
      final transactionId = uri.queryParameters['transaction_id'] ??
          uri.queryParameters['transactionId'] ??
          '';

      debugPrint('[DKPayService] Callback params: status=$status, ref=$reference, txId=$transactionId');

      final data = PaymentCallbackData(
        status: status,
        reference: reference,
        transactionId: transactionId,
      );

      // Buffer untuk cold start (widget tree belum siap)
      if (isColdStart) {
        _pendingCallback = data;
        debugPrint('[DKPayService] Disimpan sebagai pendingCallback.');
      }

      // Broadcast ke semua listener yang sudah subscribe
      _callbackController.add(data);
    } else {
      debugPrint('[DKPayService] URI diabaikan (scheme/host tidak cocok): ${uri.scheme}://${uri.host}');
    }
  }

  // ───────────────── Build Deeplink Outgoing ─────────────────
  /// Buat URL deeplink untuk membuka Dompet Kampus Global.
  ///
  /// Output: `dompetkampus://pay?merchant_id=...&amount=...&reference=...&callback=...`
  static String buildDeeplinkUrl({
    required String reference,
    required double amount,
    String merchantId = 'MCH_PASAR_MALAM',
    String merchantName = 'Pasar Malam',
    String? description,
  }) {
    final uri = Uri(
      scheme: 'dompetkampus',
      host: 'pay',
      queryParameters: {
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'amount': amount.toInt().toString(),
        'description': (description != null && description.isNotEmpty)
            ? description
            : 'Pembayaran $reference',
        'reference': reference,
        'callback': 'pasarmalam://payment-callback',
      },
    );

    final urlStr = uri.toString();
    debugPrint('[DKPayService] Deeplink outgoing: $urlStr');
    return urlStr;
  }

  void dispose() {
    _callbackController.close();
  }
}
