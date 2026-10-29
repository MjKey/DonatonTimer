import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Receives donations via Centrifugo v2 using widget token authentication.
class DonationAlertsAdapter extends BaseDonationServiceAdapter {
  DonationAlertsAdapter({
    http.Client? httpClient,
    WebSocketChannel Function(Uri)? socketConnector,
  }) : _httpClient = httpClient ?? http.Client(),
       _socketConnector = socketConnector ?? WebSocketChannel.connect;

  static const availableDomains = ['com', 'ru'];
  static final _socketUri = Uri.parse(
    'wss://centrifugo.donationalerts.com/connection/websocket',
  );
  static const _timeout = Duration(seconds: 15);
  static const _maxReconnectAttempts = 10;

  final http.Client _httpClient;
  final Logger _logger = Logger('DonationAlertsAdapter');
  final WebSocketChannel Function(Uri) _socketConnector;
  final _pending = <int, _PendingRequest>{};
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _sessionTimer;
  Timer? _reconnectTimer;
  String _widgetToken = '';
  String _domain = 'com';
  String? _donationChannel;
  bool _active = false;
  int _generation = 0;
  int _requestId = 0;
  int _reconnectAttempts = 0;
  DateTime? _sessionExpiresAt;
  @override
  String get serviceName => 'DonationAlerts';

  /// Accepts either a token or a full widget URL.
  static String extractToken(String input) {
    final value = input.trim();
    return Uri.tryParse(value)?.queryParameters['token'] ?? value;
  }

  @override
  Future<void> connect(Map<String, dynamic> config) async {
    final disconnecting = disconnect();
    final generation = _generation;
    await disconnecting;
    if (generation != _generation) throw StateError('Подключение отменено');
    _widgetToken = extractToken(config['token'] as String? ?? '');
    _domain = config['domain'] as String? ?? 'com';
    if (_widgetToken.isEmpty || !availableDomains.contains(_domain)) {
      updateStatus(ConnectionStatus.error);
      throw ArgumentError('DonationAlerts: проверьте токен и домен');
    }
    // Keep accepting the legacy socketServer setting, but use Centrifugo
    // to receive donations regardless of its saved value.
    _active = true;
    _reconnectAttempts = 0;
    updateStatus(ConnectionStatus.connecting);
    try {
      await _openSession(generation);
    } catch (error) {
      _connectionLost(
        generation,
        'ошибка подключения: $error',
        retry: error is! _ApiFailure || !error.requiresNewToken,
      );
      rethrow;
    }
  }

  bool _isCurrent(int generation) => _active && generation == _generation;

  void _checkSession(int generation) {
    if (!_isCurrent(generation)) throw StateError('Подключение отменено');
  }

  Future<Map<String, dynamic>> _api(
    String path, {
    String? bearer,
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.https('www.donationalerts.$_domain', '/api/v1$path', query);
    final headers = <String, String>{
      if (bearer != null) 'Authorization': 'Bearer $bearer',
      if (body != null) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    late http.Response response;
    try {
      response =
          await (body == null
                  ? _httpClient.get(uri, headers: headers)
                  : _httpClient.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(body),
                    ))
              .timeout(_timeout);
    } catch (error) {
      // Omit the request URI and HTTP exception because they may contain a token.
      throw StateError('API $path: ${error.runtimeType}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _ApiFailure(path, response.statusCode);
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw StateError('API $path: ответ не в формате JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw StateError('API $path: некорректный ответ');
    }
    final code = int.tryParse(decoded['code'].toString());
    // The widget API returns errors, including invalid tokens, with HTTP 202.
    if ((code != null && code != 0) || decoded['success'] == false) {
      throw _ApiFailure(path, response.statusCode, code: code);
    }
    return decoded;
  }

  Future<void> _openSession(int generation) async {
    LogManager.info('DonationAlerts: авторизация виджета для Centrifugo...');
    final session = await _api('/token/widget', query: {'token': _widgetToken});
    _checkSession(generation);
    final apiToken = session['data']['token'] as String;
    final profile = await _api('/user/widget', bearer: apiToken);
    _checkSession(generation);
    final user = profile['data'] as Map<String, dynamic>;
    final userId = user['id'];
    final connectionToken = user['socket_connection_token'] as String;
    if (userId == null || connectionToken.isEmpty) {
      throw StateError('В профиле нет данных для подключения Centrifugo');
    }
    final channelName = '\$alerts:donation_$userId';
    _donationChannel = channelName;
    _sessionExpiresAt = null;

    final channel = _socketConnector(_socketUri);
    _channel = channel;
    _subscription = channel.stream.listen(
      (message) {
        if (_isCurrent(generation)) _handleMessage(message);
      },
      onError: (_) => _connectionLost(generation, 'ошибка WebSocket'),
      onDone: () => _connectionLost(
        generation,
        'WebSocket закрыт (код ${channel.closeCode})',
      ),
    );
    await channel.ready.timeout(_timeout);
    _checkSession(generation);
    final connection = await _rpc({'token': connectionToken});
    _checkSession(generation);
    final clientId = connection['client'] as String;
    _scheduleSessionRenewal(connection, generation);

    final authorization = await _api(
      '/centrifuge/subscribe',
      bearer: apiToken,
      body: {
        'client': clientId,
        'channels': [channelName],
      },
    );
    _checkSession(generation);
    final channels = authorization['channels'] as List;
    final authorized = channels.cast<Map<String, dynamic>>().firstWhere(
      (entry) => entry['channel'] == channelName,
    );
    final subscribed = await _rpc({
      'channel': channelName,
      'token': authorized['token'] as String,
    }, method: 1);
    _checkSession(generation);
    _scheduleSessionRenewal(subscribed, generation);
    _reconnectAttempts = 0;
    updateStatus(ConnectionStatus.connected);
    LogManager.info('DonationAlerts: подписка подтверждена: $channelName');
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      try {
        await _rpc({}, method: 7);
      } catch (_) {
        _connectionLost(generation, 'нет ответа на ping');
      }
    });
  }

  Future<Map<String, dynamic>> _rpc(
    Map<String, dynamic> params, {
    int? method,
  }) async {
    final id = ++_requestId;
    final request = _PendingRequest(allowEmptyResult: method == 7);
    final channel = _channel;
    if (channel == null) throw StateError('WebSocket не подключён');
    _pending[id] = request;
    try {
      channel.sink.add(
        jsonEncode({'id': id, 'method': ?method, 'params': params}),
      );
      return await request.reply.future.timeout(_timeout);
    } finally {
      _pending.remove(id);
    }
  }

  void _handleMessage(dynamic message) {
    final raw = message is List<int>
        ? utf8.decode(message, allowMalformed: true)
        : message.toString();
    // Centrifugo v2 may batch multiple JSON commands separated by newlines.
    for (final line in const LineSplitter().convert(raw)) {
      if (line.trim().isEmpty) continue;
      try {
        final packet = jsonDecode(line) as Map<String, dynamic>;
        _logger.fine(() => 'DonationAlerts ← ${jsonEncode(packet)}');
        final id = packet['id'];
        if (id != null) {
          final request = _pending.remove(id);
          if (request == null) continue;
          final reply = request.reply;
          final error = packet['error'];
          if (error != null) {
            reply.completeError(StateError('Centrifugo: код ${error['code']}'));
          } else if (packet['result'] is Map) {
            reply.complete(Map<String, dynamic>.from(packet['result'] as Map));
          } else if (request.allowEmptyResult && packet['result'] == null) {
            // Centrifugo 2.5 acknowledges pings with a packet containing only id.
            reply.complete({});
          } else {
            reply.completeError(StateError('Centrifugo: ответ без result'));
          }
          continue;
        }
        final result = packet['result'];
        if (result is! Map || result['channel'] != _donationChannel) continue;
        if (result['type'] != null && result['type'] != 0) continue;
        final publication = result['data'];
        if (publication is Map && publication['data'] is Map) {
          _handleDonation(
            Map<String, dynamic>.from(publication['data'] as Map),
          );
        }
      } catch (_) {
        LogManager.warning('DonationAlerts: некорректное сообщение Centrifugo');
      }
    }
  }

  void _handleDonation(Map<String, dynamic> data) {
    // The donation channel identifies the event type; alert_type is not provided.
    if (data['is_shown']?.toString() == '1') return;
    final id = data['id']?.toString();
    final amount = double.tryParse(data['amount'].toString());
    final currency = data['currency'] as String? ?? '';
    if (id == null ||
        amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        currency.isEmpty) {
      LogManager.warning('DonationAlerts: в донате нет id, суммы или валюты');
      return;
    }
    final donation = Donation(
      id: '${serviceName}_$id',
      serviceName: serviceName,
      username: data['username'] as String? ?? 'Anonymous',
      amount: amount,
      currency: currency,
      message: data['message'] as String?,
      timestamp: DateTime.now(),
    );
    LogManager.info(
      'DonationAlerts: донат от ${donation.username} - $amount $currency',
    );
    emitDonation(donation);
  }

  void _scheduleSessionRenewal(Map<String, dynamic> result, int generation) {
    final ttl = result['ttl'];
    if (result['expires'] != true || ttl is! num || ttl <= 0) return;
    final renewAt = DateTime.now().add(
      Duration(seconds: ttl.toInt() > 30 ? ttl.toInt() - 30 : 1),
    );
    if (_sessionExpiresAt != null && !renewAt.isBefore(_sessionExpiresAt!)) {
      return;
    }
    _sessionExpiresAt = renewAt;
    _sessionTimer?.cancel();
    _sessionTimer = Timer(renewAt.difference(DateTime.now()), () {
      _connectionLost(generation, 'обновление срока авторизации');
    });
  }

  void _connectionLost(int generation, String reason, {bool retry = true}) {
    if (!_isCurrent(generation)) return;
    // Immediately invalidate stale HTTP responses and socket callbacks.
    final nextGeneration = ++_generation;
    LogManager.warning('DonationAlerts: $reason');
    unawaited(_closeSocket());
    if (!retry || _reconnectAttempts >= _maxReconnectAttempts) {
      _active = false;
      updateStatus(ConnectionStatus.error);
      if (retry) {
        LogManager.error(
          'DonationAlerts: превышено число попыток переподключения',
        );
      }
      return;
    }
    updateStatus(ConnectionStatus.reconnecting);
    final attempt = ++_reconnectAttempts;
    _reconnectTimer = Timer(Duration(seconds: 5 * attempt), () async {
      if (!_isCurrent(nextGeneration)) return;
      LogManager.info('DonationAlerts: попытка переподключения #$attempt');
      try {
        await _openSession(nextGeneration);
      } catch (error) {
        _connectionLost(
          nextGeneration,
          'ошибка подключения: $error',
          retry: error is! _ApiFailure || !error.requiresNewToken,
        );
      }
    });
  }

  Future<void> _closeSocket() async {
    _pingTimer?.cancel();
    _sessionTimer?.cancel();
    final subscription = _subscription;
    final channel = _channel;
    _subscription = null;
    _channel = null;
    for (final request in _pending.values) {
      request.reply.completeError(StateError('WebSocket отключён'));
    }
    _pending.clear();
    await subscription?.cancel();
    try {
      await channel?.sink.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // The server may have already closed the connection.
    }
  }

  @override
  Future<void> disconnect() async {
    _active = false;
    _generation++;
    _reconnectTimer?.cancel();
    await _closeSocket();
    _donationChannel = null;
    updateStatus(ConnectionStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    _httpClient.close();
  }
}

class _PendingRequest {
  _PendingRequest({required this.allowEmptyResult});

  final bool allowEmptyResult;
  final reply = Completer<Map<String, dynamic>>();
}

class _ApiFailure implements Exception {
  const _ApiFailure(this.path, this.status, {this.code});

  final String path;
  final int status;
  final int? code;

  bool get requiresNewToken => code == 1001 || status == 401 || status == 403;

  @override
  String toString() => requiresNewToken
      ? 'API $path: требуется актуальный токен виджета (HTTP $status, код $code)'
      : 'API $path: HTTP $status, код $code';
}
