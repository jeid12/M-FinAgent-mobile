import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config.dart';
import '../models/summary.dart';
import '../models/transaction.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(
      path: '${base.path}/v1/$path'.replaceAll('//', '/'),
      queryParameters: queryParams,
    );
  }

  Future<List<TransactionItem>> fetchTransactions(String phoneNumber) async {
    final response = await _client.get(_uri('transactions', {
      'phone_number': phoneNumber,
      'limit': '50',
    }));

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
    }));

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
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber, 'question': question}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to ask coach');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['answer'] as String;
  }

  WebSocketChannel openAlertChannel(String phoneNumber) {
    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(
      scheme: AppConfig.apiBaseUrl.startsWith('https') ? 'wss' : 'ws',
      path: '/v1/alerts/ws/$phoneNumber',
    );
    return WebSocketChannel.connect(uri);
  }
}
