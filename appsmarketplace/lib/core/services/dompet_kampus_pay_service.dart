import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uni_links/uni_links.dart';

class PaymentCallbackData {
  final String status;
  final String reference;
  final String transactionId;

  PaymentCallbackData({
    required this.status,
    required this.reference,
    required this.transactionId,
  });

  @override
  String toString() {
    return 'PaymentCallbackData(status: $status, reference: $reference, transactionId: $transactionId)';
  }
}

class DompetKampusPayService {
  DompetKampusPayService._internal();

  static final DompetKampusPayService instance = DompetKampusPayService._internal();

  final StreamController<PaymentCallbackData> _callbackController =
      StreamController<PaymentCallbackData>.broadcast();

  Stream<PaymentCallbackData> get onCallback => _callbackController.stream;

  PaymentCallbackData? _pendingCallback;

  PaymentCallbackData? consumePendingCallback() {
    final callback = _pendingCallback;
    _pendingCallback = null;
    return callback;
  }

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('Skipping deep link initialization on web');
      return;
    }

    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (err) {
      debugPrint('Failed to process uri stream error: $err');
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('Received DeepLink URI: $uri');
    if (uri.scheme == 'mycatalog' && uri.host == 'payment-callback') {
      final status = uri.queryParameters['status'] ?? '';
      final reference = uri.queryParameters['reference'] ?? '';
      final transactionId = uri.queryParameters['transactionId'] ??
          uri.queryParameters['transaction_id'] ??
          '';

      if (status.isNotEmpty && reference.isNotEmpty) {
        final data = PaymentCallbackData(
          status: status,
          reference: reference,
          transactionId: transactionId,
        );

        if (_callbackController.hasListener) {
          _callbackController.add(data);
        } else {
          _pendingCallback = data;
        }
      }
    }
  }

  static String buildDeeplinkUrl({
    required String reference,
    required double amount,
  }) {
    return Uri(
      scheme: 'dompetkampus',
      host: 'pay',
      queryParameters: {
        'reference': reference,
        'amount': amount.toStringAsFixed(0),
        'callback_url': 'mycatalog://payment-callback',
      },
    ).toString();
  }

  void dispose() {
    _callbackController.close();
  }
}
