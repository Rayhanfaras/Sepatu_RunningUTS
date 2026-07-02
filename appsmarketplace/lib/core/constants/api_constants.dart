import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      // Use localhost for web if your backend runs on the same machine.
      // Change this to the server IP if needed, e.g. 'http://192.168.1.14:8081/v1'.
      return 'http://localhost:8081/v1';
    }

    return 'http://127.0.0.1:8081/v1';
  }

  // Auth endpoints
  static const String verifyToken = '/auth/verify-token';

  // Product endpoints
  static const String products = '/products';

  // Timeout
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
