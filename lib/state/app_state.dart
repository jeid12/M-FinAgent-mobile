import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  WebSocketChannel? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  String get smsPermissionLabel => switch (smsPermissionState) {
        SmsPermissionState.granted => 'Granted',
        SmsPermissionState.denied => 'Denied',
        SmsPermissionState.unsupported => 'Unavailable',
      };

  String get activeIdentityLabel => activePhoneNumber ?? 'Guest';

  Future<void> initialize() async {
    initialized = true;
    loading = false;
    notifyListeners();
  }

  Future<void> register(String phoneNumber) async {
    await _startAuthFlow(
      action: () => _api.registerWithPhone(phoneNumber),
      phoneNumber: phoneNumber,
    );
  }

  Future<void> login(String phoneNumber) async {
    await _startAuthFlow(
      action: () => _api.loginWithPhone(phoneNumber),
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
    chatMessages = [];
    alerts = [];
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
    notifyListeners();
  }

  Future<void> _startSmsIngestion() async {
    smsPermissionState = await _smsListener.start(
      onSupportedSms: (provider, smsText) async {
        final phoneNumber = activePhoneNumber;
        if (phoneNumber == null) {
          return;
        }

        try {
          await _api.ingestSms(
            provider: provider,
            phoneNumber: phoneNumber,
            smsText: smsText,
          );
          await refreshData();
        } catch (_) {
          // Keep the app responsive when backend is temporarily unavailable.
        }
      },
    );
    notifyListeners();
  }

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

    try {
      final result = await Future.wait([
        _api.fetchSummary(phoneNumber),
        _api.fetchTransactions(phoneNumber),
      ]);

      summary = result[0] as SpendingSummary;
      transactions = result[1] as List<TransactionItem>;
      backendOnline = true;
    } catch (e) {
      error = e.toString();
      backendOnline = false;
    }

    loading = false;
    notifyListeners();
  }

  Future<void> sendQuestion(String question) async {
    if (question.trim().isEmpty) {
      return;
    }

    final phoneNumber = activePhoneNumber;
    if (!isAuthenticated || phoneNumber == null) {
      return;
    }

    chatMessages = [
      ...chatMessages,
      ChatMessage(text: question, fromUser: true),
    ];
    notifyListeners();

    try {
      final answer = await _api.askCoach(phoneNumber, question);
      chatMessages = [
        ...chatMessages,
        ChatMessage(text: answer, fromUser: false),
      ];
      backendOnline = true;
    } catch (_) {
      chatMessages = [
        ...chatMessages,
        ChatMessage(text: 'Coach is temporarily unavailable. Try again.', fromUser: false),
      ];
      backendOnline = false;
    }

    notifyListeners();
  }

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

    // In web_socket_channel v3, failed handshakes can surface on `ready`.
    unawaited(
      _socket!.ready.then((_) {
        if (_isDisposed) {
          return;
        }
        _reconnectAttempts = 0;
        backendOnline = true;
        _attachAlertStream();
      }).catchError((_) {
        if (_isDisposed) {
          return;
        }
        backendOnline = false;
        alerts = ['Realtime channel unavailable.', ...alerts].take(8).toList();
        notifyListeners();
        _scheduleReconnect();
      }),
    );
  }

  void _attachAlertStream() {
    if (_socket == null || _isDisposed) {
      return;
    }

    _socket!.stream.listen((event) {
      try {
        final payload = jsonDecode(event as String) as Map<String, dynamic>;
        final message = payload['message']?.toString() ?? 'New spending alert.';
        alerts = [message, ...alerts].take(8).toList();
        backendOnline = true;
      } catch (_) {
        alerts = ['Realtime alert received.', ...alerts].take(8).toList();
      }
      notifyListeners();
    }, onError: (_) {
      backendOnline = false;
      alerts = ['Realtime channel disconnected.', ...alerts].take(8).toList();
      notifyListeners();
      _scheduleReconnect();
    }, onDone: () {
      if (_isDisposed) {
        return;
      }
      backendOnline = false;
      alerts = ['Realtime channel closed. Reconnecting...', ...alerts].take(8).toList();
      notifyListeners();
      _scheduleReconnect();
    }, cancelOnError: false);
  }

  void _scheduleReconnect() {
    if (_isDisposed) {
      return;
    }

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
