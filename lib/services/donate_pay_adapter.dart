import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для DonatePay.
/// Использует WebSocket с протоколом Centrifugo v2.
class DonatePayAdapter extends BaseDonationServiceAdapter {
  // Centrifugo v2 uses different URL format
  static const String _wsUrl = 'wss://centrifugo.donatepay.ru/connection/websocket';
  static const String _tokenEndpoint = 'https://donatepay.ru/api/v2/socket/token';
  static const String _userEndpoint = 'https://donatepay.ru/api/v1/user';
  
  final Logger _logger = Logger('DonatePayAdapter');
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _apiKey;
  int? _userId;
  String? _token;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  int _messageId = 1;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 25);
  
  @override
  String get serviceName => 'DonatePay';
  
  @override
  Future<void> connect(Map<String, dynamic> config) async {
    _apiKey = config['apiKey'] as String?;
    
    if (_apiKey == null || _apiKey!.isEmpty) {
      LogManager.warning('DonatePay: API ключ не указан');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    updateStatus(ConnectionStatus.connecting);
    LogManager.info('DonatePay: подключение...');
    
    try {
      // Get user ID from API
      LogManager.info('DonatePay: получение User ID...');
      _userId = await _getUserId();
      if (_userId == null) {
        LogManager.error('DonatePay: не удалось получить User ID');
        updateStatus(ConnectionStatus.error);
        return;
      }
      LogManager.info('DonatePay: User ID = $_userId');
      
      // Get connection token
      LogManager.info('DonatePay: получение токена...');
      _token = await _getConnectionToken();
      if (_token == null) {
        LogManager.error('DonatePay: не удалось получить токен');
        updateStatus(ConnectionStatus.error);
        return;
      }
      LogManager.info('DonatePay: токен получен');
      
      // Connect via WebSocket
      await _initWebSocket();
      
    } catch (e, stackTrace) {
      _logger.severe('Error connecting to DonatePay: $e\n$stackTrace');
      LogManager.error('DonatePay: ошибка подключения - $e');
      updateStatus(ConnectionStatus.error);
    }
  }
  
  Future<void> _initWebSocket() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      LogManager.info('DonatePay: WebSocket создан');
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          LogManager.error('DonatePay: ошибка WebSocket - $error');
          updateStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          LogManager.warning('DonatePay: соединение закрыто (code: $closeCode, reason: $closeReason)');
          if (status != ConnectionStatus.disconnected) {
            updateStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
      );
      
      // Send connect command after WebSocket is ready
      // Small delay to ensure connection is established
      Future.delayed(const Duration(milliseconds: 100), _sendConnect);
      
    } catch (e) {
      LogManager.error('DonatePay: ошибка создания WebSocket - $e');
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }


  void _handleMessage(dynamic message) {
    final data = message.toString();
    LogManager.info('DonatePay: получено: ${data.length > 200 ? '${data.substring(0, 200)}...' : data}');
    
    try {
      final json = jsonDecode(data);
      
      // Handle response with id (connect or subscribe response)
      if (json['id'] != null && json['result'] != null) {
        final result = json['result'] as Map<String, dynamic>;
        
        // Connection successful - has 'client' field
        if (result['client'] != null) {
          LogManager.info('DonatePay: подключено (client: ${result['client']}, version: ${result['version']})');
          _subscribeToChannel();
          return;
        }
        
        // Subscription successful - has 'recoverable' or 'epoch'
        if (result['recoverable'] != null || result['epoch'] != null) {
          LogManager.info('DonatePay: подписка активна');
          updateStatus(ConnectionStatus.connected);
          _reconnectAttempts = 0;
          _startPingTimer();
          return;
        }
      }
      
      // Handle push messages (donations) - no 'id', has 'result' with 'channel' and 'data'
      if (json['id'] == null && json['result'] != null) {
        final result = json['result'] as Map<String, dynamic>;
        if (result['channel'] != null && result['data'] != null) {
          final pubData = result['data'] as Map<String, dynamic>;
          if (pubData['data'] != null) {
            _handlePublication(pubData['data'] as Map<String, dynamic>);
          }
          return;
        }
      }
      
      // Handle error
      if (json['error'] != null) {
        final error = json['error'];
        LogManager.error('DonatePay: ошибка от сервера - $error');
        return;
      }
      
    } catch (e) {
      LogManager.info('DonatePay: не-JSON сообщение: $data');
    }
  }
  
  void _sendConnect() {
    // DonatePay Centrifugo format - connect without method
    final connectCmd = {
      'params': {
        'token': _token,
        'name': 'dart',
      },
      'id': _messageId++,
    };
    _channel?.sink.add(jsonEncode(connectCmd));
    LogManager.info('DonatePay: отправлен connect');
  }
  
  void _subscribeToChannel() {
    // DonatePay uses notifications#USER_ID channel format
    final channelName = 'notifications#$_userId';
    // method:1 = subscribe in DonatePay's Centrifugo
    final subscribeCmd = {
      'method': 1,
      'params': {
        'channel': channelName,
      },
      'id': _messageId++,
    };
    _channel?.sink.add(jsonEncode(subscribeCmd));
    LogManager.info('DonatePay: подписка на $channelName');
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      // DonatePay ping format: method 7
      final pingCmd = {
        'method': 7,
        'id': _messageId++,
      };
      _channel?.sink.add(jsonEncode(pingCmd));
    });
  }
  
  void _handlePublication(Map<String, dynamic> data) {
    try {
      // DonatePay format: data.notification contains the donation info
      final notification = data['notification'] as Map<String, dynamic>?;
      if (notification == null) {
        LogManager.info('DonatePay: нет notification в данных');
        return;
      }
      
      // Check if this is a donation notification
      final notificationType = notification['type'] as String?;
      if (notificationType != 'donation') {
        LogManager.info('DonatePay: пропуск события типа $notificationType');
        return;
      }
      
      // Parse vars - it's a JSON string in DonatePay format
      Map<String, dynamic> vars;
      final varsRaw = notification['vars'];
      if (varsRaw is String) {
        vars = jsonDecode(varsRaw) as Map<String, dynamic>;
      } else if (varsRaw is Map) {
        vars = Map<String, dynamic>.from(varsRaw);
      } else {
        LogManager.warning('DonatePay: неизвестный формат vars');
        return;
      }
      
      final id = notification['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final username = vars['name'] as String? ?? 'Anonymous';
      final sum = _parseDoubleField(vars['sum']);
      
      // Get currency from transaction if available
      final transaction = data['transaction'] as Map<String, dynamic>?;
      final currency = transaction?['currency'] as String? ?? 'RUB';
      final donationMessage = vars['comment'] as String?;
      
      // Only process RUB donations
      if (currency != 'RUB') {
        LogManager.info('DonatePay: пропуск не-RUB доната ($currency)');
        return;
      }
      
      final donation = Donation(
        id: '${serviceName}_$id',
        serviceName: serviceName,
        username: username,
        amount: sum,
        currency: currency,
        message: donationMessage,
        timestamp: DateTime.now(),
      );
      
      LogManager.info('DonatePay: донат от $username - $sum $currency');
      emitDonation(donation);
      
    } catch (e, stackTrace) {
      LogManager.error('DonatePay: ошибка обработки сообщения - $e');
      _logger.severe('Error: $e\n$stackTrace');
    }
  }
  
  /// Makes HTTP request with retry logic for rate limiting (429 errors).
  Future<http.Response?> _requestWithRetry(
    Future<http.Response> Function() request, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 5),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await request();
        
        if (response.statusCode == 429) {
          if (attempt < maxRetries) {
            final delay = initialDelay * attempt;
            LogManager.warning('DonatePay: rate limit (429), повтор через ${delay.inSeconds}с');
            await Future.delayed(delay);
            continue;
          }
          return response;
        }
        
        return response;
      } catch (e) {
        if (attempt < maxRetries) {
          final delay = initialDelay * attempt;
          LogManager.warning('DonatePay: ошибка запроса, повтор через ${delay.inSeconds}с');
          await Future.delayed(delay);
          continue;
        }
        rethrow;
      }
    }
    return null;
  }

  Future<int?> _getUserId() async {
    try {
      final response = await _requestWithRetry(
        () => http.get(Uri.parse('$_userEndpoint?access_token=$_apiKey')),
      );
      
      if (response == null) return null;
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final userId = data['data']['id'] as int?;
          final userName = data['data']['name'] as String?;
          LogManager.info('DonatePay: пользователь $userName (ID: $userId)');
          return userId;
        }
      }
      
      LogManager.error('DonatePay: ошибка получения пользователя - ${response.statusCode}');
      return null;
    } catch (e) {
      LogManager.error('DonatePay: ошибка запроса пользователя - $e');
      return null;
    }
  }
  
  Future<String?> _getConnectionToken() async {
    try {
      final response = await _requestWithRetry(
        () => http.post(
          Uri.parse(_tokenEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': _apiKey}),
        ),
      );
      
      if (response == null) return null;
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] as String?;
      }
      
      LogManager.error('DonatePay: ошибка получения токена - ${response.statusCode}');
      return null;
    } catch (e) {
      LogManager.error('DonatePay: ошибка запроса токена - $e');
      return null;
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
      LogManager.error('DonatePay: превышено число попыток переподключения');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      LogManager.info('DonatePay: попытка переподключения #$_reconnectAttempts');
      updateStatus(ConnectionStatus.reconnecting);
      _initWebSocket();
    });
  }
  
  @override
  Future<void> disconnect() async {
    LogManager.info('DonatePay: отключение...');
    updateStatus(ConnectionStatus.disconnected);
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    
    _channel = null;
    _subscription = null;
    LogManager.info('DonatePay: отключено');
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
