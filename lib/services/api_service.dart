import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config.dart';
import '../models/summary.dart';
import '../models/transaction.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(
      path: '${base.path}/v1/$path'.replaceAll('//', '/'),
      queryParameters: queryParams,
    );
  }

  Future<void> authenticate(String phoneNumber) async {
    final response = await _client.post(
      _uri('auth/register'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to authenticate mobile app');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = payload['access_token']?.toString();
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Backend returned empty access token');
    }
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) {
      headers['content-type'] = 'application/json';
    }
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<TransactionItem>> fetchTransactions(String phoneNumber) async {
    final response = await _client.get(_uri('transactions', {
      'phone_number': phoneNumber,
      'limit': '50',
    }), headers: _headers());

    if (response.statusCode != 200) {
      throw Exception('Failed to load transactions');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((entry) => TransactionItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<SpendingSummary> fetchSummary(String phoneNumber) async {
    final response = await _client.get(_uri('transactions/summary', {
      'phone_number': phoneNumber,
      'days': '7',
    }), headers: _headers());

    if (response.statusCode != 200) {
      throw Exception('Failed to load summary');
    }

    return SpendingSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> askCoach(String phoneNumber, String question) async {
    final response = await _client.post(
      _uri('chat'),
      headers: _headers(json: true),
      body: jsonEncode({'phone_number': phoneNumber, 'question': question}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to ask coach');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['answer'] as String;
  }

  Future<void> ingestSms({
    required String provider,
    required String phoneNumber,
    required String smsText,
  }) async {
    final response = await _client.post(
      _uri('transactions/ingest'),
      headers: _headers(json: true),
      body: jsonEncode({
        'provider': provider,
        'phone_number': phoneNumber,
        'sms_text': smsText,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw Exception('Failed to ingest SMS transaction');
    }
  }

  WebSocketChannel openAlertChannel(String phoneNumber) {
    final query = <String, String>{};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      query['token'] = _accessToken!;
    }

    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(
      scheme: AppConfig.apiBaseUrl.startsWith('https') ? 'wss' : 'ws',
      path: '/v1/alerts/ws/$phoneNumber',
      queryParameters: query.isEmpty ? null : query,
    );
    return WebSocketChannel.connect(uri);
  }
}
