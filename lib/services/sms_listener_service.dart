import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SmsPermissionState { unsupported, denied, granted }

class SmsListenerService {
  SmsListenerService();

  static const MethodChannel _methodChannel = MethodChannel('m_finagent_mobile/sms_method');
  static const EventChannel _eventChannel = EventChannel('m_finagent_mobile/sms_events');

  bool _started = false;
  StreamSubscription<dynamic>? _subscription;

  Future<SmsPermissionState> start({
    required Future<void> Function(String provider, String smsText) onSupportedSms,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return SmsPermissionState.unsupported;
    }

    if (_started) {
      return SmsPermissionState.granted;
    }

    final granted = await _methodChannel.invokeMethod<bool>('requestPermissions');
    if (granted != true) {
      return SmsPermissionState.denied;
    }

    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is! Map) {
        return;
      }

      final body = (event['body'] ?? '').toString();
      final address = (event['address'] ?? '').toString();
      final provider = _detectProvider(address, body);
      if (provider == null) {
        return;
      }

      unawaited(onSupportedSms(provider, body));
    }, onError: (_) {});

    _started = true;
    return SmsPermissionState.granted;
  }

  String? _detectProvider(String? address, String body) {
    final source = '${address ?? ''} ${body.toLowerCase()}';
    if (source.contains('mtn')) {
      return 'MTN';
    }
    if (source.contains('airtel')) {
      return 'Airtel';
    }
    return null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
