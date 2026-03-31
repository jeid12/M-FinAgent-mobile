import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  // Default LAN URL for real devices on the same Wi-Fi.
  static const String _realDeviceApiBaseUrl = String.fromEnvironment(
    'REAL_DEVICE_API_BASE_URL',
    defaultValue: 'http://193.168.201.200:8000',
  );

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
    final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && isLocalHost) {
      if (Platform.isAndroid && _isAndroidEmulator) {
        return uri.replace(host: '10.0.2.2').toString();
      }
      // Physical mobile device should call laptop LAN URL, not localhost.
      return _realDeviceApiBaseUrl;
    }

    return _rawApiBaseUrl;
  }

  static const String phoneNumber = '+250788000001';
}
