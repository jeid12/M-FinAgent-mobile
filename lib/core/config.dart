import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Set ANDROID_EMULATOR=true only when running on Android emulator.
  static const bool _isAndroidEmulator = bool.fromEnvironment(
    'ANDROID_EMULATOR',
    defaultValue: false,
  );

  static String get apiBaseUrl {
    final uri = Uri.parse(_rawApiBaseUrl);

    // Android emulator cannot access host machine through localhost.
    if (!kIsWeb &&
        Platform.isAndroid &&
        _isAndroidEmulator &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return _rawApiBaseUrl;
  }

  static const String phoneNumber = '+250788000001';
}
