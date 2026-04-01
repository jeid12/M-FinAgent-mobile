import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config.dart';
import '../models/chat_message.dart';
import '../models/summary.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(
      path: '${base.path}/v1/$path'.replaceAll('//', '/'),
      queryParameters: queryParams,
    );
  }

  String _networkFailureMessage(Object error, Uri uri) {
    if (error is SocketException) {
      final reason = error.message.isEmpty ? 'Network unavailable' : error.message;
      return 'Network error while reaching ${uri.host}:${uri.hasPort ? uri.port : '(default)'} ($reason). '
          'Verify API_BASE_URL and open https://${uri.host}/health on this device to confirm DNS/connectivity.';
    }
    if (error is http.ClientException) {
      return 'Request failed for ${uri.toString()}: ${error.message}. '
          'Verify API_BASE_URL and internet/device connectivity.';
    }
    return 'Unexpected network error: $error';
  }

  Future<http.Response> _postJson(
    Uri uri,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) async {
    try {
      return await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
    } on SocketException catch (e) {
      throw Exception(_networkFailureMessage(e, uri));
    } on http.ClientException catch (e) {
      throw Exception(_networkFailureMessage(e, uri));
    }
  }

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await _client.get(uri, headers: headers);
    } on SocketException catch (e) {
      throw Exception(_networkFailureMessage(e, uri));
    } on http.ClientException catch (e) {
      throw Exception(_networkFailureMessage(e, uri));
    }
  }

  Future<http.Response> _putJson(
    Uri uri,
    Map<String, dynamic> payload, {
    Map<String, String>? headers,
  }) async {
    try {
      return await _client.put(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
    } on SocketException catch (e) {
      throw Exception(_networkFailureMessage(e, uri));
    } on http.ClientException catch (e) {
      throw Exception(_networkFailureMessage(e, uri));
    }
  }

  Future<void> registerWithPhone(String phoneNumber, String password) async {
    await _authenticate(
      endpoint: 'auth/register',
      payload: {'phone_number': phoneNumber, 'password': password},
      failureMessage: 'Failed to register mobile app user',
    );
  }

  Future<void> loginWithPhone(String phoneNumber, String password) async {
    await _authenticate(
      endpoint: 'auth/login',
      payload: {'phone_number': phoneNumber, 'password': password},
      failureMessage: 'Failed to login mobile app user',
    );
  }

  Future<void> _authenticate({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String failureMessage,
  }) async {
    final authUri = _uri(endpoint);
    final response = await _postJson(
      authUri,
      payload,
      headers: const {'content-type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(failureMessage);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = decoded['access_token']?.toString();
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw Exception('Backend returned empty access token');
    }
  }

  void clearAuthToken() {
    _accessToken = null;
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) headers['content-type'] = 'application/json';
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _errorDetail(http.Response response) {
    final rawBody = response.body.trim();
    if (rawBody.isEmpty) return 'Request failed';
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return (decoded['detail'] ?? decoded['message'] ?? decoded['error'] ?? rawBody)
            .toString();
      }
      return rawBody;
    } catch (_) {
      return rawBody;
    }
  }

  Future<List<TransactionItem>> fetchTransactions() async {
    final uri = _uri('transactions', {'limit': '50'});
    final response = await _get(
      uri,
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load transactions (${response.statusCode}): ${_errorDetail(response)}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((entry) => TransactionItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<SpendingSummary> fetchSummary() async {
    final uri = _uri('transactions/summary', {'days': '7'});
    final response = await _get(
      uri,
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load summary (${response.statusCode}): ${_errorDetail(response)}',
      );
    }

    return SpendingSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> askCoach(String question) async {
    final chatUri = _uri('chat');
    final response = await _postJson(
      chatUri,
      {'question': question},
      headers: _headers(json: true),
    );

    if (response.statusCode != 200) {
      final rawBody = response.body.trim();
      String detail = 'Request failed';

      if (rawBody.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawBody);
          if (decoded is Map<String, dynamic>) {
            detail = (decoded['detail'] ?? decoded['message'] ?? decoded['error'] ?? rawBody)
                .toString();
          } else {
            detail = rawBody;
          }
        } catch (_) {
          detail = rawBody;
        }
      }

      throw Exception('Coach request failed (${response.statusCode}): $detail');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['answer'] as String;
  }

  Future<UserProfile> fetchProfile() async {
    final uri = _uri('auth/me');
    final response = await _get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load profile (${response.statusCode}): ${_errorDetail(response)}',
      );
    }
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfilePatch(Map<String, dynamic> patchPayload) async {
    final uri = _uri('auth/me');
    var response = await _putJson(
      uri,
      patchPayload,
      headers: _headers(json: true),
    );

    if (response.statusCode == 405) {
      // Backward compatibility when server still exposes POST /auth/me.
      response = await _postJson(
        uri,
        patchPayload,
        headers: _headers(json: true),
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update profile (${response.statusCode}): ${_errorDetail(response)}',
      );
    }
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<String> uploadProfileImageToCloudinary(File imageFile) async {
    if (AppConfig.cloudinaryCloudName.isEmpty || AppConfig.cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final uploadUri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uploadUri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${_errorDetail(response)}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final url = body['secure_url']?.toString() ?? '';
    if (url.isEmpty) {
      throw Exception('Cloudinary upload succeeded but secure_url is missing.');
    }
    return url;
  }

  /// Fetch server-side chat history (newest last).
  Future<List<ChatMessage>> fetchChatHistory({int limit = 50}) async {
    final uri = _uri('chat/history', {'limit': limit.toString()});
    final response = await _get(
      uri,
      headers: _headers(),
    );

    if (response.statusCode != 200) return const [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = data['messages'] as List<dynamic>? ?? [];
    return messages
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ingest a single SMS transaction.
  ///
  /// [occurredAt] carries the original SMS timestamp so historical messages
  /// are stored with the correct date, not "now".
  Future<void> ingestSms({
    required String provider,
    required String phoneNumber,
    required String smsText,
    DateTime? occurredAt,
  }) async {
    final ingestUri = _uri('transactions/ingest');
    final response = await _postJson(
      ingestUri,
      {
        'provider': provider,
        'phone_number': phoneNumber,
        'sms_text': smsText,
        'occurred_at': (occurredAt ?? DateTime.now().toUtc()).toIso8601String(),
      },
      headers: _headers(json: true),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw Exception(
        'Failed to ingest SMS transaction (${response.statusCode}): ${_errorDetail(response)}',
      );
    }
  }

  WebSocketChannel openAlertChannel() {
    final query = <String, String>{};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      query['token'] = _accessToken!;
    }

    final uri = Uri.parse(AppConfig.apiBaseUrl).replace(
      scheme: AppConfig.apiBaseUrl.startsWith('https') ? 'wss' : 'ws',
      path: '/v1/alerts/ws/me',
      queryParameters: query.isEmpty ? null : query,
    );
    return WebSocketChannel.connect(uri);
  }
}
