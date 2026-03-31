import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SmsPermissionState { unsupported, denied, granted }

/// A parsed SMS event carrying enough metadata for the backend ingest endpoint.
class SmsEvent {
  const SmsEvent({
    required this.provider,
    required this.body,
    required this.occurredAt,
  });

  final String provider;
  final String body;
  final DateTime occurredAt;
}

/// Expanded list of financial SMS senders recognised in Rwanda.
const _financialKeywords = [
  // Mobile money
  'mtn', 'momo', 'airtel',
  // Loan providers
  'mocash', 'mo cash',
  // Banks
  'bank of kigali', 'bk mobile', 'equity bank', 'i&m bank',
  'cogebanque', 'access bank', 'gt bank',
  // Utilities / services
  'irembo', 'wasac', 'rwasco', 'reg ', 'umeme',
  'tap&go', 'tapngo',
  // Generic financial keywords (catches unlabelled transaction alerts)
  'rwf', 'frw', 'transaction', 'payment', 'received', 'sent to',
  'withdrawn', 'deposited', 'balance',
];

class SmsListenerService {
  SmsListenerService();

  static const MethodChannel _methodChannel =
      MethodChannel('m_finagent_mobile/sms_method');
  static const EventChannel _eventChannel =
      EventChannel('m_finagent_mobile/sms_events');

  bool _started = false;
  StreamSubscription<dynamic>? _subscription;

  // -------------------------------------------------------------------------
  // Start real-time listener for incoming SMS
  // -------------------------------------------------------------------------
  Future<SmsPermissionState> start({
    required Future<void> Function(SmsEvent event) onFinancialSms,
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

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is! Map) return;

        final body = (event['body'] ?? '').toString();
        final address = (event['address'] ?? '').toString();
        final timestampMs = event['timestamp'] as int?;
        final occurredAt = timestampMs != null
            ? DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true)
            : DateTime.now().toUtc();

        final provider = _detectProvider(address, body);
        if (provider == null) return;

        unawaited(onFinancialSms(SmsEvent(
          provider: provider,
          body: body,
          occurredAt: occurredAt,
        )));
      },
      onError: (_) {},
    );

    _started = true;
    return SmsPermissionState.granted;
  }

  // -------------------------------------------------------------------------
  // Fetch historical SMS from the inbox (called once after login)
  // -------------------------------------------------------------------------
  Future<List<SmsEvent>> fetchHistoricalSms({int maxMessages = 200}) async {
    if (kIsWeb || !Platform.isAndroid) return const [];

    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'fetchHistoricalSms',
        {'maxMessages': maxMessages},
      );
      if (result == null) return const [];

      final events = <SmsEvent>[];
      for (final item in result) {
        if (item is! Map) continue;
        final body = (item['body'] ?? '').toString();
        final address = (item['address'] ?? '').toString();
        final timestampMs = item['timestamp'] as int?;
        final occurredAt = timestampMs != null
            ? DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true)
            : DateTime.now().toUtc();

        final provider = _detectProvider(address, body);
        if (provider == null) continue;

        events.add(SmsEvent(
          provider: provider,
          body: body,
          occurredAt: occurredAt,
        ));
      }
      return events;
    } catch (_) {
      // Native side may not implement fetchHistoricalSms yet — degrade silently
      return const [];
    }
  }

  Future<List<SmsEvent>> fetchCapturedSmsQueue() async {
    if (kIsWeb || !Platform.isAndroid) return const [];

    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>('fetchCapturedSmsQueue');
      if (result == null) return const [];

      final events = <SmsEvent>[];
      for (final item in result) {
        if (item is! Map) continue;
        final body = (item['body'] ?? '').toString();
        final address = (item['address'] ?? '').toString();
        final timestampMs = item['timestamp'] as int?;
        final occurredAt = timestampMs != null
            ? DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true)
            : DateTime.now().toUtc();

        final provider = _detectProvider(address, body);
        if (provider == null) continue;

        events.add(SmsEvent(provider: provider, body: body, occurredAt: occurredAt));
      }
      return events;
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearCapturedSmsQueue() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod<bool>('clearCapturedSmsQueue');
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Provider detection — now covers MTN, Airtel, MoCash, banks, utilities
  // -------------------------------------------------------------------------
  String? _detectProvider(String address, String body) {
    final combined = '${address.toLowerCase()} ${body.toLowerCase()}';

    if (combined.contains('mtn') || combined.contains('momo')) return 'MTN';
    if (combined.contains('airtel')) return 'Airtel';
    if (combined.contains('mocash') || combined.contains('mo cash')) return 'MoCash';
    if (combined.contains('bank of kigali') || combined.contains('bk mobile')) return 'BK';
    if (combined.contains('equity bank')) return 'Equity';
    if (combined.contains('i&m bank')) return 'I&M';
    if (combined.contains('cogebanque')) return 'Cogebanque';
    if (combined.contains('irembo')) return 'Irembo';
    if (combined.contains('wasac') || combined.contains('rwasco')) return 'WASAC';
    if (combined.contains('reg ') || combined.contains('umeme')) return 'REG';
    if (combined.contains('tap&go') || combined.contains('tapngo')) return 'Tap&Go';

    // Generic catch: any SMS mentioning RWF/FRW and financial verbs
    if ((combined.contains('rwf') || combined.contains('frw')) &&
        _hasFinancialVerb(combined)) {
      return 'Other';
    }

    return null;
  }

  bool _hasFinancialVerb(String text) {
    const verbs = [
      'received', 'sent', 'paid', 'payment', 'withdrawn', 'deposited',
      'balance', 'transaction', 'transfer', 'credited', 'debited',
    ];
    return verbs.any(text.contains);
  }

  bool isFinancialSms(String address, String body) =>
      _detectProvider(address, body) != null;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
