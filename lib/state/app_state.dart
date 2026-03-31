import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message.dart';
import '../models/summary.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/sms_listener_service.dart';

class AppState extends ChangeNotifier {
  AppState({ApiService? apiService, SmsListenerService? smsListener})
      : _api = apiService ?? ApiService(),
        _smsListener = smsListener ?? SmsListenerService();

  final ApiService _api;
  final SmsListenerService _smsListener;

  bool initialized = false;
  bool authLoading = false;
  bool isAuthenticated = false;
  String? activePhoneNumber;
  String? authError;
  bool loading = true;
  bool backendOnline = false;
  SmsPermissionState smsPermissionState = SmsPermissionState.unsupported;
  String? error;
  SpendingSummary summary = SpendingSummary.empty();
  List<TransactionItem> transactions = [];
  List<ChatMessage> chatMessages = [];
  List<String> alerts = [];

  // Historical SMS ingestion progress
  bool historicalSmsLoading = false;
  int historicalSmsTotal = 0;
  int historicalSmsDone = 0;
  DateTime? lastSmsDetectedAt;
  DateTime? lastSmsSyncedAt;
  String? smsSyncIssue;

  WebSocketChannel? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  static const _chatCacheKey = 'chat_messages_cache';

  String get smsPermissionLabel => switch (smsPermissionState) {
        SmsPermissionState.granted => 'Granted',
        SmsPermissionState.denied => 'Denied',
        SmsPermissionState.unsupported => 'Unavailable',
      };

  String get activeIdentityLabel => activePhoneNumber ?? 'Guest';

  String get historicalSmsProgress =>
      historicalSmsTotal > 0 ? '$historicalSmsDone / $historicalSmsTotal' : '';

  String get smsSyncStatus {
    if (smsPermissionState == SmsPermissionState.denied) {
      return 'SMS permission denied. Enable SMS permissions in app settings.';
    }
    if (smsPermissionState == SmsPermissionState.unsupported) {
      return 'SMS auto-ingest works on Android devices.';
    }
    if (smsSyncIssue != null && smsSyncIssue!.isNotEmpty) {
      return smsSyncIssue!;
    }
    if (lastSmsSyncedAt != null) {
      return 'Last SMS synced at ${lastSmsSyncedAt!.toLocal()}';
    }
    if (lastSmsDetectedAt != null) {
      return 'SMS detected, syncing...';
    }
    return 'Waiting for financial SMS...';
  }

  Future<void> initialize() async {
    initialized = true;
    loading = false;
    notifyListeners();
  }

  Future<void> register(String phoneNumber, String password) async {
    await _startAuthFlow(
      action: () => _api.registerWithPhone(phoneNumber, password),
      phoneNumber: phoneNumber,
    );
  }

  Future<void> login(String phoneNumber, String password) async {
    await _startAuthFlow(
      action: () => _api.loginWithPhone(phoneNumber, password),
      phoneNumber: phoneNumber,
    );
  }

  Future<void> _startAuthFlow({
    required Future<void> Function() action,
    required String phoneNumber,
  }) async {
    authLoading = true;
    authError = null;
    notifyListeners();

    try {
      await action();
      isAuthenticated = true;
      activePhoneNumber = phoneNumber;
      backendOnline = true;
      await _startSession();
    } catch (e) {
      authError = e.toString();
      backendOnline = false;
    } finally {
      authLoading = false;
      notifyListeners();
    }
  }

  Future<void> _startSession() async {
    alerts = [];
    await _loadChatHistory();
    await refreshData();
    await _startSmsIngestion();
    _connectAlerts();
  }

  Future<void> logout() async {
    isAuthenticated = false;
    activePhoneNumber = null;
    authError = null;
    _api.clearAuthToken();
    _reconnectTimer?.cancel();
    _socket?.sink.close();
    _socket = null;

    summary = SpendingSummary.empty();
    transactions = [];
    chatMessages = [];
    alerts = [];
    loading = false;
    historicalSmsLoading = false;
    lastSmsDetectedAt = null;
    lastSmsSyncedAt = null;
    smsSyncIssue = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // SMS ingestion — real-time listener + one-shot historical fetch
  // ---------------------------------------------------------------------------

  Future<void> _startSmsIngestion() async {
    smsPermissionState = await _smsListener.start(
      onFinancialSms: (SmsEvent event) async {
        final phoneNumber = activePhoneNumber;
        if (phoneNumber == null) return;
        lastSmsDetectedAt = DateTime.now();
        smsSyncIssue = null;
        notifyListeners();
        try {
          await _api.ingestSms(
            provider: event.provider,
            phoneNumber: phoneNumber,
            smsText: event.body,
            occurredAt: event.occurredAt,
          );
          lastSmsSyncedAt = DateTime.now();
          smsSyncIssue = null;
          await refreshData();
        } catch (e) {
          final reason = e.toString().replaceFirst('Exception: ', '').trim();
          smsSyncIssue = reason.isEmpty ? 'Failed to sync incoming SMS.' : reason;
          alerts = ['SMS sync failed: $smsSyncIssue', ...alerts].take(8).toList();
          notifyListeners();
        }
      },
    );

    if (smsPermissionState != SmsPermissionState.granted) {
      smsSyncIssue = smsSyncStatus;
    }
    notifyListeners();

    await _ingestCapturedQueue();

    if (smsPermissionState == SmsPermissionState.granted) {
      unawaited(_ingestHistoricalSms());
    }
  }

  Future<void> _ingestCapturedQueue() async {
    final phoneNumber = activePhoneNumber;
    if (phoneNumber == null) return;

    final queued = await _smsListener.fetchCapturedSmsQueue();
    if (queued.isEmpty) return;

    var failed = 0;
    for (final event in queued) {
      try {
        await _api.ingestSms(
          provider: event.provider,
          phoneNumber: phoneNumber,
          smsText: event.body,
          occurredAt: event.occurredAt,
        );
        lastSmsSyncedAt = DateTime.now();
      } catch (_) {
        failed++;
      }
    }

    if (failed == 0) {
      await _smsListener.clearCapturedSmsQueue();
      smsSyncIssue = null;
      alerts = ['Offline SMS synced: ${queued.length} item(s).', ...alerts].take(8).toList();
    } else {
      smsSyncIssue = 'Offline SMS sync has $failed failed items.';
      alerts = ['Offline SMS sync: $failed failed items.', ...alerts].take(8).toList();
    }

    notifyListeners();
    await refreshData();
  }

  Future<void> _ingestHistoricalSms() async {
    final phoneNumber = activePhoneNumber;
    if (phoneNumber == null) return;

    final historical = await _smsListener.fetchHistoricalSms(maxMessages: 300);
    if (historical.isEmpty) return;

    historicalSmsLoading = true;
    historicalSmsTotal = historical.length;
    historicalSmsDone = 0;
    var failed = 0;
    notifyListeners();

    for (final event in historical) {
      try {
        await _api.ingestSms(
          provider: event.provider,
          phoneNumber: phoneNumber,
          smsText: event.body,
          occurredAt: event.occurredAt,
        );
      } catch (_) {
        // Individual failures are non-fatal — continue processing
        failed++;
      }
      historicalSmsDone++;
      // Notify every 10 items to avoid flooding UI
      if (historicalSmsDone % 10 == 0) notifyListeners();
    }

    historicalSmsLoading = false;
    if (failed > 0) {
      smsSyncIssue = 'Synced with $failed failed SMS items.';
      alerts = ['Historical SMS sync: $failed failed items.', ...alerts].take(8).toList();
    }
    notifyListeners();
    await refreshData();
  }

  // ---------------------------------------------------------------------------
  // Data refresh
  // ---------------------------------------------------------------------------

  Future<void> refreshData() async {
    final phoneNumber = activePhoneNumber;
    if (!isAuthenticated || phoneNumber == null) {
      loading = false;
      error = null;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    String? summaryError;
    String? transactionsError;

    try {
      summary = await _api.fetchSummary();
    } catch (e) {
      summaryError = e.toString().replaceFirst('Exception: ', '').trim();
    }

    try {
      transactions = await _api.fetchTransactions();
    } catch (e) {
      transactionsError = e.toString().replaceFirst('Exception: ', '').trim();
    }

    if (summaryError == null && transactionsError == null) {
      backendOnline = true;
    } else {
      backendOnline = false;
      final parts = <String>[];
      if (summaryError != null) parts.add(summaryError);
      if (transactionsError != null) parts.add(transactionsError);
      error = parts.join(' | ');
      if (error!.contains('(401)') || error!.toLowerCase().contains('missing bearer token')) {
        error = '$error. Session expired; please log in again.';
      }
    }

    loading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Chat — send message, persist locally and on server
  // ---------------------------------------------------------------------------

  Future<void> sendQuestion(String question) async {
    if (question.trim().isEmpty) return;

    final phoneNumber = activePhoneNumber;
    if (!isAuthenticated || phoneNumber == null) return;

    chatMessages = [
      ...chatMessages,
      ChatMessage(text: question, fromUser: true),
    ];
    notifyListeners();

    try {
      final answer = await _api.askCoach(question);
      chatMessages = [
        ...chatMessages,
        ChatMessage(text: answer, fromUser: false),
      ];
      backendOnline = true;
    } catch (e) {
      final reason = e.toString().replaceFirst('Exception: ', '').trim();
      chatMessages = [
        ...chatMessages,
        ChatMessage(
          text: reason.isEmpty
              ? 'Coach is temporarily unavailable. Try again.'
              : 'Coach is temporarily unavailable: $reason',
          fromUser: false,
        ),
      ];
      backendOnline = false;
    }

    await _saveChatHistory();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Chat history persistence (SharedPreferences)
  // ---------------------------------------------------------------------------

  Future<void> _loadChatHistory() async {
    // First try to restore from server-side history
    try {
      final serverMessages = await _api.fetchChatHistory(limit: 50);
      if (serverMessages.isNotEmpty) {
        chatMessages = serverMessages;
        await _saveChatHistory();
        notifyListeners();
        return;
      }
    } catch (_) {
      // Fall back to local cache
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chatCacheKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        chatMessages = list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      chatMessages = [];
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep last 100 messages locally
      final toSave = chatMessages.length > 100
          ? chatMessages.sublist(chatMessages.length - 100)
          : chatMessages;
      await prefs.setString(
        _chatCacheKey,
        jsonEncode(toSave.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // WebSocket alerts
  // ---------------------------------------------------------------------------

  void _connectAlerts() {
    final phoneNumber = activePhoneNumber;
    if (_isDisposed || !isAuthenticated || phoneNumber == null || !_api.hasAccessToken) {
      return;
    }

    _reconnectTimer?.cancel();
    _socket?.sink.close();
    _socket = null;

    try {
      _socket = _api.openAlertChannel();
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    unawaited(
      _socket!.ready.then((_) {
        if (_isDisposed) return;
        _reconnectAttempts = 0;
        backendOnline = true;
        _attachAlertStream();
      }).catchError((_) {
        if (_isDisposed) return;
        alerts = ['Realtime channel unavailable.', ...alerts].take(8).toList();
        notifyListeners();
        _scheduleReconnect();
      }),
    );
  }

  void _attachAlertStream() {
    if (_socket == null || _isDisposed) return;

    _socket!.stream.listen(
      (event) {
        try {
          final payload = jsonDecode(event as String) as Map<String, dynamic>;
          final message = payload['message']?.toString() ?? 'New spending alert.';
          alerts = [message, ...alerts].take(8).toList();
          backendOnline = true;
        } catch (_) {
          alerts = ['Realtime alert received.', ...alerts].take(8).toList();
        }
        notifyListeners();
      },
      onError: (_) {
        alerts = ['Realtime channel disconnected.', ...alerts].take(8).toList();
        notifyListeners();
        _scheduleReconnect();
      },
      onDone: () {
        if (_isDisposed) return;
        alerts = ['Realtime channel closed. Reconnecting...', ...alerts].take(8).toList();
        notifyListeners();
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    final delaySeconds = (1 << _reconnectAttempts).clamp(2, 30);
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(0, 12);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _connectAlerts);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _socket?.sink.close();
    unawaited(_smsListener.dispose());
    super.dispose();
  }
}
