import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для Donatty.
/// Использует SSE (Server-Sent Events) для получения донатов.
class DonattyAdapter extends BaseDonationServiceAdapter {
  final Logger _logger = Logger('DonattyAdapter');

  HttpClient? _httpClient;
  HttpClientRequest? _request;
  HttpClientResponse? _response;
  StreamSubscription? _subscription;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  String? _groupId;
  String? _linkToken;
  String? _accessToken;

  @override
  String get serviceName => 'Donatty';

  /// Extracts tokens from the URL.
  /// Supports: https://widgets.donatty.com/group/?ref={group_id}&token={link_token}
  static Map<String, String>? extractTokens(String input) {
    if (input.contains('donatty.com') && input.contains('ref=') && input.contains('token=')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        final ref = uri.queryParameters['ref'];
        final token = uri.queryParameters['token'];
        if (ref != null && token != null && ref.isNotEmpty && token.isNotEmpty) {
          return {'group_id': ref, 'link_token': token};
        }
      }
    }
    return null;
  }

  @override
  Future<void> connect(Map<String, dynamic> config) async {
    final urlOrTokens = config['token'] as String?;
    
    if (urlOrTokens == null || urlOrTokens.isEmpty) {
      _logger.warning('Token or URL is required for Donatty connection');
      LogManager.warning('Donatty: токен или ссылка не указаны');
      updateStatus(ConnectionStatus.error);
      return;
    }

    final tokens = extractTokens(urlOrTokens);
    if (tokens != null) {
      _groupId = tokens['group_id'];
      _linkToken = tokens['link_token'];
    } else {
      // It might be a token configuration, but we strictly need both group_id and link_token or a full link
      _logger.warning('Invalid Donatty link format. Ensure it contains ref and token.');
      LogManager.warning('Donatty: неверный формат ссылки. Необходима ссылка с ref и token.');
      updateStatus(ConnectionStatus.error);
      return;
    }

    updateStatus(ConnectionStatus.connecting);
    _logger.info('Connecting to Donatty...');
    LogManager.info('Donatty: получение access_token...');

    await _initConnection();
  }

  Future<void> _initConnection() async {
    try {
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);

      // 1. Get access token
      final authUrl = Uri.parse('https://api-014.donatty.com/auth/tokens/$_linkToken');
      final authRequest = await _httpClient!.getUrl(authUrl);
      final authResponse = await authRequest.close();

      if (authResponse.statusCode != 200) {
        throw Exception('Failed to get auth token. Status code: ${authResponse.statusCode}');
      }

      final authBody = await authResponse.transform(utf8.decoder).join();
      final authJson = json.decode(authBody) as Map<String, dynamic>;
      
      _accessToken = authJson['response']?['accessToken'] as String?;

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Access token not found in response');
      }

      LogManager.info('Donatty: access_token получен, подключение к SSE...');

      // 2. Connect to SSE
      final sseUrl = Uri.parse('https://api-014.donatty.com/widgets/$_groupId/sse?jwt=$_accessToken');
      _request = await _httpClient!.getUrl(sseUrl);
      _request!.headers.set('Accept', 'text/event-stream');
      _request!.headers.set('Cache-Control', 'no-cache');
      
      _response = await _request!.close();

      if (_response!.statusCode != 200) {
        throw Exception('Failed to connect to SSE. Status code: ${_response!.statusCode}');
      }

      LogManager.info('Donatty: подключено успешно (SSE)');
      updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      // 3. Listen to SSE stream
      _subscription = _response!
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onError: (error) {
              _logger.severe('SSE stream error: $error');
              LogManager.error('Donatty: ошибка SSE потока - $error');
              _handleDisconnect();
            },
            onDone: () {
              _logger.warning('SSE connection closed');
              LogManager.warning('Donatty: соединение закрыто');
              _handleDisconnect();
            },
          );

    } catch (e, stackTrace) {
      _logger.severe('Error connecting to Donatty: $e\n$stackTrace');
      LogManager.error('Donatty: ошибка подключения - $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (status != ConnectionStatus.disconnected) {
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleLine(String line) {
    if (line.isEmpty) return;

    if (line.startsWith('data')) {
      final jsonStartIndex = line.indexOf('{');
      if (jsonStartIndex == -1) return;
      
      final jsonStr = line.substring(jsonStartIndex).trim();
      if (jsonStr.isEmpty) return;

      try {
        final data = json.decode(jsonStr) as Map<String, dynamic>;
        _handleEventData(data);
      } catch (e) {
        _logger.warning('Error parsing SSE line: $e\nLine was: $line');
      }
    }
  }

  void _handleEventData(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    
    if (action == 'PING') {
      _logger.fine('Received PING');
      return;
    }

    if (action == 'PROXY') {
      final proxyData = data['data'] as Map<String, dynamic>?;
      if (proxyData == null) return;

      final events = proxyData['events'] as List<dynamic>?;
      if (events == null) return;

      for (final eventItem in events) {
        final eventContainer = eventItem['event'] as Map<String, dynamic>?;
        if (eventContainer == null) continue;

        final eventAction = eventContainer['action'] as String?;
        if (eventAction == 'DATA') {
          final eventData = eventContainer['data'] as Map<String, dynamic>?;
          if (eventData != null) {
            _processDonation(eventData);
          }
        }
      }
    }
  }

  void _processDonation(Map<String, dynamic> eventData) {
    final eventType = eventData['streamEventType'] as String?;
    if (eventType != 'DONATTY_DONATION') return;

    try {
      final subscriber = eventData['subscriber'] as String? ?? 'Anonymous';
      final message = eventData['message'] as String?;
      final amount = _parseDoubleField(eventData['amount']);
      final currency = eventData['currency'] as String? ?? 'RUB';
      
      // Parse streamEventData for detailed info like ID
      String id = DateTime.now().millisecondsSinceEpoch.toString();
      final streamEventDataStr = eventData['streamEventData'] as String?;
      if (streamEventDataStr != null) {
        try {
          final parsedEventData = json.decode(streamEventDataStr) as Map<String, dynamic>;
          if (parsedEventData['refId'] != null) {
            id = parsedEventData['refId'].toString();
          }
        } catch (_) {}
      }

      final donation = Donation(
        id: '${serviceName}_$id',
        serviceName: serviceName,
        username: subscriber,
        amount: amount,
        currency: currency,
        message: message,
        timestamp: DateTime.now(),
      );

      _logger.info('Donation: $subscriber - $amount $currency');
      LogManager.info('Donatty: донат от $subscriber - $amount $currency');
      emitDonation(donation);

    } catch (e, stackTrace) {
      _logger.severe('Error processing Donatty donation: $e\n$stackTrace');
      LogManager.error('Donatty: ошибка обработки доната - $e');
    }
  }

  double _parseDoubleField(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.severe('Max reconnect attempts reached');
      LogManager.error('Donatty: превышено число попыток переподключения');
      updateStatus(ConnectionStatus.error);
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      _logger.info('Reconnect attempt #$_reconnectAttempts');
      LogManager.info('Donatty: попытка переподключения #$_reconnectAttempts');
      updateStatus(ConnectionStatus.reconnecting);
      _initConnection();
    });
  }

  @override
  Future<void> disconnect() async {
    _logger.info('Disconnecting from Donatty...');
    LogManager.info('Donatty: отключение...');
    updateStatus(ConnectionStatus.disconnected);

    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    
    // Close HTTP request and client if possible
    _httpClient?.close(force: true);
    
    _subscription = null;
    _request = null;
    _response = null;
    _httpClient = null;

    _logger.info('Disconnected from Donatty');
    LogManager.info('Donatty: отключено');
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
