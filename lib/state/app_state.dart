import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config.dart';
import '../models/chat_message.dart';
import '../models/summary.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  AppState({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;

  bool loading = true;
  String? error;
  SpendingSummary summary = SpendingSummary.empty();
  List<TransactionItem> transactions = [];
  List<ChatMessage> chatMessages = [];
  List<String> alerts = [];
  WebSocketChannel? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;

  Future<void> initialize() async {
    await refreshData();
    _connectAlerts();
  }

  Future<void> refreshData() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await Future.wait([
        _api.fetchSummary(AppConfig.phoneNumber),
        _api.fetchTransactions(AppConfig.phoneNumber),
      ]);

      summary = result[0] as SpendingSummary;
      transactions = result[1] as List<TransactionItem>;
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> sendQuestion(String question) async {
    if (question.trim().isEmpty) {
      return;
    }

    chatMessages = [
      ...chatMessages,
      ChatMessage(text: question, fromUser: true),
    ];
    notifyListeners();

    try {
      final answer = await _api.askCoach(AppConfig.phoneNumber, question);
      chatMessages = [
        ...chatMessages,
        ChatMessage(text: answer, fromUser: false),
      ];
    } catch (_) {
      chatMessages = [
        ...chatMessages,
        ChatMessage(text: 'Coach is temporarily unavailable. Try again.', fromUser: false),
      ];
    }

    notifyListeners();
  }

  void _connectAlerts() {
    if (_isDisposed) {
      return;
    }

    _reconnectTimer?.cancel();
    _socket?.sink.close();
    _socket = null;

    try {
      _socket = _api.openAlertChannel(AppConfig.phoneNumber);
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
        _attachAlertStream();
      }).catchError((_) {
        if (_isDisposed) {
          return;
        }
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
      } catch (_) {
        alerts = ['Realtime alert received.', ...alerts].take(8).toList();
      }
      notifyListeners();
    }, onError: (_) {
      alerts = ['Realtime channel disconnected.', ...alerts].take(8).toList();
      notifyListeners();
      _scheduleReconnect();
    }, onDone: () {
      if (_isDisposed) {
        return;
      }
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
    super.dispose();
  }
}
