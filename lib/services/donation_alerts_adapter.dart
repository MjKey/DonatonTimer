import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для DonationAlerts.
/// Использует WebSocket с протоколом Socket.IO v2.
class DonationAlertsAdapter extends BaseDonationServiceAdapter {
  // Available socket servers
  static const List<String> availableSockets = [
    'socket5',
    'socket',
    'socket1',
    'socket2',
    'socket3',
    'socket4',
  ];
  
  final Logger _logger = Logger('DonationAlertsAdapter');
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _token;
  String _socketServer = 'socket5';
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 25);
  
  String get _wsUrl => 'wss://$_socketServer.donationalerts.ru/socket.io/?EIO=3&transport=websocket';
  
  @override
  String get serviceName => 'DonationAlerts';
  
  /// Extracts token from URL or returns the input if it's already a token.
  /// Supports: https://www.donationalerts.com/widget/alerts?group_id=1&token=XXX
  static String extractToken(String input) {
    if (input.contains('donationalerts.com') && input.contains('token=')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
    }
    return input;
  }
  
  @override
  Future<void> connect(Map<String, dynamic> config) async {
    final rawToken = config['token'] as String?;
    _token = rawToken != null ? extractToken(rawToken) : null;
    _socketServer = config['socketServer'] as String? ?? 'socket5';
    
    if (_token == null || _token!.isEmpty) {
      _logger.warning('Token is required for DonationAlerts connection');
      LogManager.warning('DonationAlerts: токен не указан');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    updateStatus(ConnectionStatus.connecting);
    _logger.info('Connecting to DonationAlerts via $_socketServer...');
    LogManager.info('DonationAlerts: подключение через $_socketServer...');
    
    await _initWebSocket();
  }
  
  Future<void> _initWebSocket() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      LogManager.info('DonationAlerts: WebSocket создан ($_socketServer)');
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.severe('WebSocket error: $error');
          LogManager.error('DonationAlerts: ошибка WebSocket - $error');
          updateStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          _logger.warning('WebSocket connection closed');
          LogManager.warning('DonationAlerts: соединение закрыто');
          if (status != ConnectionStatus.disconnected) {
            updateStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
      );
      
    } catch (e, stackTrace) {
      _logger.severe('Error connecting to DonationAlerts: $e\n$stackTrace');
      LogManager.error('DonationAlerts: ошибка подключения - $e');
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }


  void _handleMessage(dynamic message) {
    final data = message.toString();
    _logger.fine('Received: $data');
    
    // Socket.IO v2 ping/pong: server sends "2", client responds "3"
    if (data == '2') {
      _channel?.sink.add('3');
      return;
    }
    
    // Initial handshake: 0{"sid":...}
    if (data.startsWith('0{')) {
      _logger.info('Received handshake, sending connect');
      LogManager.info('DonationAlerts: handshake получен');
      // Send connect packet (type 40 in Socket.IO)
      _channel?.sink.add('40');
      return;
    }
    
    // Connect acknowledgment: 40 or 40{...}
    if (data == '40' || data.startsWith('40{')) {
      _logger.info('Connected to Socket.IO namespace');
      LogManager.info('DonationAlerts: namespace подключён, отправка токена...');
      // Send authentication with token
      _sendAuth();
      return;
    }
    
    // Message packet: 42[...]
    if (data.startsWith('42')) {
      _handleEventMessage(data);
      return;
    }
    
    // Ack packet: 43[...]
    if (data.startsWith('43')) {
      _logger.info('Received ack: $data');
      return;
    }
  }
  
  void _sendAuth() {
    // DonationAlerts expects add-user event with token
    final authMessage = '42["add-user",{"token":"$_token","type":"minor"}]';
    _channel?.sink.add(authMessage);
    _logger.info('Sent auth token');
    LogManager.info('DonationAlerts: токен отправлен');
    
    // Consider connected after sending auth
    updateStatus(ConnectionStatus.connected);
    _reconnectAttempts = 0;
    _startPingTimer();
    LogManager.info('DonationAlerts: подключено успешно');
  }
  
  void _startPingTimer() {
    // Socket.IO v2: server sends ping "2", client responds with pong "3"
    // We don't need to send pings ourselves - just respond to server pings
    // The _handleMessage already handles this with the "2" -> "3" response
    _pingTimer?.cancel();
    // Keep timer reference for cleanup, but don't send anything
    // Server will ping us and we respond in _handleMessage
  }
  
  void _handleEventMessage(String data) {
    try {
      // Remove "42" prefix and parse JSON array
      final jsonStr = data.substring(2);
      final arr = json.decode(jsonStr) as List;
      
      if (arr.isEmpty) return;
      
      final eventName = arr[0] as String;
      _logger.info('Event: $eventName');
      
      if (eventName == 'donation' && arr.length > 1) {
        _handleDonation(arr[1]);
      }
    } catch (e) {
      _logger.warning('Error parsing event: $e');
    }
  }
  
  void _handleDonation(dynamic data) {
    try {
      Map<String, dynamic> donationData;
      
      if (data is String) {
        donationData = json.decode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        donationData = Map<String, dynamic>.from(data);
      } else {
        _logger.warning('Unknown donation data format: ${data.runtimeType}');
        return;
      }
      
      final alertType = _parseIntField(donationData['alert_type']);
      final isShown = _parseIntField(donationData['is_shown']);
      final currency = donationData['currency'] as String? ?? '';
      
      // alert_type == 1 means donation, is_shown == 0 means not yet displayed
      if (alertType != 1 || isShown != 0) {
        _logger.info('Skipping: alert_type=$alertType, is_shown=$isShown');
        return;
      }
      
      // Only process RUB donations
      if (currency != 'RUB') {
        _logger.info('Skipping non-RUB donation: $currency');
        return;
      }
      
      final id = donationData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final username = donationData['username'] as String? ?? 'Anonymous';
      final amount = _parseDoubleField(donationData['amount_main']);
      final donationMessage = donationData['message'] as String?;
      
      final donation = Donation(
        id: '${serviceName}_$id',
        serviceName: serviceName,
        username: username,
        amount: amount,
        currency: currency,
        message: donationMessage,
        timestamp: DateTime.now(),
      );
      
      _logger.info('Donation: $username - $amount $currency');
      LogManager.info('DonationAlerts: донат от $username - $amount $currency');
      emitDonation(donation);
      
    } catch (e, stackTrace) {
      _logger.severe('Error processing donation: $e\n$stackTrace');
      LogManager.error('DonationAlerts: ошибка обработки доната - $e');
    }
  }
  
  int _parseIntField(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
      LogManager.error('DonationAlerts: превышено число попыток переподключения');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      _logger.info('Reconnect attempt #$_reconnectAttempts');
      LogManager.info('DonationAlerts: попытка переподключения #$_reconnectAttempts');
      updateStatus(ConnectionStatus.reconnecting);
      _initWebSocket();
    });
  }
  
  @override
  Future<void> disconnect() async {
    _logger.info('Disconnecting from DonationAlerts...');
    LogManager.info('DonationAlerts: отключение...');
    updateStatus(ConnectionStatus.disconnected);
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    
    _channel = null;
    _subscription = null;
    _logger.info('Disconnected from DonationAlerts');
    LogManager.info('DonationAlerts: отключено');
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
