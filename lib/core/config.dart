import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  // Used when API_BASE_URL is localhost on an Android physical device.
  static const String _realDeviceApiBaseUrl = String.fromEnvironment(
    'REAL_DEVICE_API_BASE_URL',
    defaultValue: 'https://m-finagent-backend.onrender.com',
  );

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://m-finagent-backend.onrender.com',
  );

  // Set ANDROID_EMULATOR=true only when running on Android emulator.
  static const bool _isAndroidEmulator = bool.fromEnvironment(
    'ANDROID_EMULATOR',
    defaultValue: false,
  );

  static String _normalizeBaseUrl(String raw) {
    // Accept common cli/env forms such as quoted values or missing scheme.
    final trimmed = raw.trim().replaceAll('"', '').replaceAll("'", '');
    if (trimmed.isEmpty) {
      return 'https://m-finagent-backend.onrender.com';
    }
    final hasScheme = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    return hasScheme ? trimmed : 'http://$trimmed';
  }

  static String get apiBaseUrl {
    final normalized = _normalizeBaseUrl(_rawApiBaseUrl);
    final uri = Uri.parse(normalized);
    final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';

    if (!kIsWeb && Platform.isAndroid && isLocalHost) {
      if (_isAndroidEmulator) {
        return uri.replace(host: '10.0.2.2').toString();
      }
      // Android physical device should call laptop LAN URL, not localhost.
      return _realDeviceApiBaseUrl;
    }

    return normalized;
  }

  static const String phoneNumber = '+250788000001';

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dxufhhhbl',
  );
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'finagent',
  );
}
