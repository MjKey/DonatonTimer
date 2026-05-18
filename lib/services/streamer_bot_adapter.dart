import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для Streamer.bot.
/// Использует WebSocket для получения событий.
class StreamerBotAdapter extends BaseDonationServiceAdapter {
  final Logger _logger = Logger('StreamerBotAdapter');

  WebSocket? _webSocket;
  StreamSubscription? _subscription;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  String? _wsUrl;

  @override
  String get serviceName => 'StreamerBot';

  List<Map<String, dynamic>> _mappings = [];

  @override
  Future<void> connect(Map<String, dynamic> config) async {
    _wsUrl = config['wsUrl'] as String?;
    
    if (_wsUrl == null || _wsUrl!.isEmpty) {
      _wsUrl = 'ws://127.0.0.1:8080/';
    }

    final mappingsStr = config['mappings'] as String?;
    if (mappingsStr != null && mappingsStr.isNotEmpty) {
      try {
        final parsed = json.decode(mappingsStr) as List;
        _mappings = parsed.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        _logger.warning('Failed to parse mappings: $e');
        _mappings = [];
      }
    } else {
      _mappings = [];
    }

    updateStatus(ConnectionStatus.connecting);
    _logger.info('Connecting to StreamerBot...');
    LogManager.info('StreamerBot: подключение к $_wsUrl...');

    await _initConnection();
  }

  Future<void> _initConnection() async {
    try {
      _webSocket = await WebSocket.connect(_wsUrl!).timeout(const Duration(seconds: 10));

      LogManager.info('StreamerBot: подключено успешно (WebSocket)');
      updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      final events = <String, List<String>>{};
      for (final m in _mappings) {
        final source = m['source'] as String?;
        final type = m['type'] as String?;
        if (source != null && type != null) {
          events.putIfAbsent(source, () => []).add(type);
        }
      }

      if (events.isEmpty) {
        LogManager.warning('StreamerBot: нет настроенных событий для подписки');
        return; // Ничего не делаем, если нет маппингов
      }

      // Подписываемся на нужные события
      final subscribeMsg = {
        "request": "Subscribe",
        "events": events,
        "id": "donatontimer"
      };
      
      _webSocket!.add(json.encode(subscribeMsg));

      _subscription = _webSocket!.listen(
        _handleMessage,
        onError: (error) {
          _logger.severe('WebSocket error: $error');
          LogManager.error('StreamerBot: ошибка WebSocket - $error');
          _handleDisconnect();
        },
        onDone: () {
          _logger.warning('WebSocket closed');
          LogManager.warning('StreamerBot: соединение закрыто');
          _handleDisconnect();
        },
      );
    } catch (e, stackTrace) {
      _logger.severe('Error connecting to StreamerBot: $e\n$stackTrace');
      LogManager.error('StreamerBot: ошибка подключения - $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (status != ConnectionStatus.disconnected) {
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    if (message is! String) return;

    try {
      final data = json.decode(message) as Map<String, dynamic>;
      
      if (data.containsKey('event') && data.containsKey('data')) {
        _handleEventData(data);
      }
    } catch (e) {
      _logger.warning('Error parsing WebSocket message: $e');
    }
  }

  void _handleEventData(Map<String, dynamic> payload) {
    final event = payload['event'] as Map<String, dynamic>?;
    final data = payload['data'] as Map<String, dynamic>?;
    
    if (event == null || data == null) return;

    final source = event['source'] as String?;
    final type = event['type'] as String?;

    try {
      for (final m in _mappings) {
        if (m['source'] == source && m['type'] == type) {
          double amount = _parseDoubleField(m['amount']);
          
          // Если сумма в настройках = 0, пытаемся вытащить её из данных самого события (динамическая сумма)
          if (amount <= 0) {
            final dataAmount = _parseDoubleField(data['amount']);
            final dataBits = _parseDoubleField(data['bits']);
            
            if (dataAmount > 0) {
              amount = dataAmount;
            } else if (dataBits > 0) {
              amount = dataBits;
            }
          }
          
          final userObj = data['user'] as Map<String, dynamic>?;
          final username = userObj?['name'] as String? ?? 
                           data['userName'] as String? ?? 
                           data['name'] as String? ?? 
                           'Anonymous';
                           
          final messageObj = data['message'];
          String? messageStr;
          if (messageObj is String) {
            messageStr = messageObj;
          } else if (messageObj is Map<String, dynamic>) {
            messageStr = messageObj['message'] as String?;
          }
          
          final id = data['msgId']?.toString() ?? data['id']?.toString();
          
          _emitDonation(username, amount, 'RUB', messageStr, id);
          return; // Processed
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Error processing StreamerBot event: $e\n$stackTrace');
      LogManager.error('StreamerBot: ошибка обработки события - $e');
    }
  }

  void _emitDonation(String username, double amount, String currency, String? message, String? eventId) {
    if (amount <= 0) return;
    
    final id = eventId ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final donation = Donation(
      id: '${serviceName}_$id',
      serviceName: serviceName,
      username: username,
      amount: amount,
      currency: currency,
      message: message,
      timestamp: DateTime.now(),
    );

    _logger.info('Donation from $serviceName: $username - $amount $currency');
    LogManager.info('StreamerBot: донат от $username - $amount $currency');
    emitDonation(donation);
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
      LogManager.error('StreamerBot: превышено число попыток переподключения');
      updateStatus(ConnectionStatus.error);
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      _logger.info('Reconnect attempt #$_reconnectAttempts');
      LogManager.info('StreamerBot: попытка переподключения #$_reconnectAttempts');
      updateStatus(ConnectionStatus.reconnecting);
      _initConnection();
    });
  }

  @override
  Future<void> disconnect() async {
    _logger.info('Disconnecting from StreamerBot...');
    LogManager.info('StreamerBot: отключение...');
    updateStatus(ConnectionStatus.disconnected);

    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _webSocket?.close();
    
    _subscription = null;
    _webSocket = null;

    _logger.info('Disconnected from StreamerBot');
    LogManager.info('StreamerBot: отключено');
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
